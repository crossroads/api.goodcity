require "goodcity/user_utils"

module Api
  module V1
    class UsersController < Api::V1::ApiController
      BROWSE_DEFAULT_PER_PAGE = 50
      BROWSE_MAX_PER_PAGE = 100

      load_and_authorize_resource :user, parent: false
      skip_load_resource :user, only: [:orders_count]
      # browse authorises itself as the list does (index) and reads only the users the list may read
      skip_load_and_authorize_resource :user, only: [:browse]

      resource_description do
        short 'List Users'
        formats ['json']
        error 401, 'Unauthorized'
        error 404, 'Not Found'
        error 422, 'Validation Error'
        error 500, 'Internal Server Error'
      end

      api :GET, '/v1/users', 'List all users'
      param :ids, Array, desc: 'Filter by user ids e.g. ids = [1,2,3,4]'
      description <<-EOS
        Note: in accordance with permissions, users will only be able to list users they are allowed to see.
        For a donor, this will be just themselves. For administrators, this will be all users.
      EOS
      def index
        @users = @users.exclude_system_users
        return search_user_and_render_json if params[:searchText].present?

        @users = @users.with_roles(params[:roles]) if params[:roles].present?
        @users = @users.where(id: ids_param) if ids_param.present?
        render json: @users.with_eager_loading, each_serializer: serializer
      end

      api :GET, '/v1/users/browse', 'Every account the caller may list, a page at a time'
      param :page, String, desc: 'From 1 (default 1)'
      param :per_page, String, desc: 'Rows a page: default 50, at most 100'
      param :roles, Array, desc: 'Only people holding one of these roles now (as the list reads it)'
      description <<-EOS
        A new route: no existing client calls it, and a server without it answers 404 (it would look for a user
        whose id is "browse"), so a client can never be handed the unpaged list by mistake.
        Ordered by last name, first name and id. Each row is slim: name, title, disabled, created_at, and the ids of
        the person's role grants and memberships, with `user_roles` (role and expires_at), `roles`,
        `organisations_users` (status) and `organisations` (names) sideloaded. No mobile, email, address or
        sign-in times: those stay on GET /users/:id. `meta` has page, per_page, total_count and total_pages.
        Who may call it: whoever may call GET /users.
      EOS
      def browse
        authorize! :index, User
        users = User.accessible_by(current_ability, :index).exclude_system_users
        users = users.with_roles(params[:roles]) if params[:roles].present?
        # (a person holding two of the named roles is joined twice by with_roles: each appears once here)
        records = User.where(id: users.select(:id))
                      .includes(user_roles: :role, organisations_users: :organisation)
                      .order(Arel.sql('LOWER(users.last_name) ASC NULLS LAST, LOWER(users.first_name) ASC NULLS LAST, users.id ASC'))
                      .page(params['page'])
                      .per(browse_per_page)
        render json: browse_json(records)
      end

      api :POST, '/v1/users', 'Create user'
      def create
        @user.assign_attributes(user_params)

        if @user.save
          if params['user']['organisations_users_ids'].present?
            @user.organisations << Organisation.find_by(id: params['user']['organisations_users_ids'])
          end

          render json: @user, serializer: serializer, include_user_roles: true, status: 201
        else
          render_error(@user.errors.full_messages.join('. '))
        end
      end

      api :GET, '/v1/users/1', 'List a user'
      description 'Returns information about a user. Note image may be empty if user is not a reviewer.'
      def show
        render json: @user, serializer: Api::V1::UserDetailsSerializer, root: 'user'
      end

      api :PUT, '/v1/users/1', 'Update user'
      param :user, Hash, required: true do
        param :last_connected, String, desc: 'Time when user last connected to server.', allow_nil: true
        param :last_disconnected, String, desc: 'Time when user disconnected from server.', allow_nil: true
      end
      def update
        @user.update(user_params)
        if @user.valid?
          render json: @user, serializer: serializer
        else
          render_error(@user.errors.full_messages.join('. '))
        end
      end

      api :DELETE, '/v1/users/1', "Delete user"
      def destroy
        UserSafeDeleteJob.perform_later(params["id"])
        render json: { result: true, reason: I18n.t('users_controller.delete_scheduled') }, status: 200
      end

      def recent_users
        @users = User.recent_orders_created_for(User.current_user.id)
        render json: @users, each_serializer: serializer
      end

      def orders_count
        render json: Order.counts_for(params[:id])
      end

      api :GET, '/v1/users/mentionable_users', 'Get mentionable users based on messageable context and roles'
      param :roles, String, desc: 'String of roles that needs to be mentioned'
      param :messageable_type, String, desc: 'Type of messageable. Offer, Item, Package etc.', allow_nil: true
      param :messageable_id, String, desc: 'Id of any messageable type for Offer, Item, Package etc.', allow_nil: true
      def mentionable_users
        return render json: { users: [] } if params['roles'].nil?

        @users = User.mentionable_users(roles: params[:roles],
                                        messageable_type: params[:messageable_type],
                                        messageable_id: params[:messageable_id],
                                        is_private: params[:is_private])

        render json: @users, each_serializer: Api::V1::UserMentionsSerializer
      end

      api :PUT, '/v1/users/merge_users', 'Merge one user details into another user'
      param :master_user_id, String, desc: 'Id of user in which other user will be merged'
      param :merged_user_id, String, desc: 'Id of user which needs to be merged and removed.'
      def merge_users
        merge_response = Goodcity::UserUtils.merge_user!(params[:master_user_id], params[:merged_user_id])

        if merge_response[:error]
          render json: merge_response, status: 422
        else
          render json: merge_response[:user], serializer: serializer
        end
      end

      api :PUT, 'v1/users/1/grant_access', 'Grant access to user using access-pass-key'
      param :access_key, String, desc: 'AccessPass key to get access'
      def grant_access
        grant_access = GrantAccessPass.new(params[:access_key], current_user.id)

        if grant_access.pass
          grant_access.grant_access_by_pass
          render json: @user, serializer: Api::V1::UserProfileSerializer
        else
          render_error('Invalid Access Pass')
        end
      end

      private

      def serializer
        Api::V1::UserSerializer
      end

      def search_user_and_render_json
        records = @users.limit(25)
        records = records.filter_users(params)

        data = ActiveModel::ArraySerializer.new(
          records,
          each_serializer: Api::V1::UserDetailsSerializer,
          include_user_roles: true,
          root: 'users'
        ).as_json
        render json: { 'meta': { 'search': params['searchText'] } }.merge(data)
      end

      def browse_per_page
        asked = params['per_page'].to_i
        asked < 1 ? BROWSE_DEFAULT_PER_PAGE : [asked, BROWSE_MAX_PER_PAGE].min
      end

      # The slim rows of the paged list, built from the preloaded associations (a fixed handful of queries a page,
      # whatever its size: no serializer `pluck`s per row).
      def browse_json(records)
        users = records.to_a
        grants = users.flat_map(&:user_roles)
        memberships = users.flat_map(&:organisations_users)
        {
          meta: { page: records.current_page, per_page: records.limit_value,
                  total_count: records.total_count, total_pages: records.total_pages },
          users: users.map do |u|
            { id: u.id, first_name: u.first_name, last_name: u.last_name, title: u.title, disabled: u.disabled,
              created_at: u.created_at, user_role_ids: u.user_roles.map(&:id),
              organisations_user_ids: u.organisations_users.map(&:id) }
          end,
          user_roles: grants.map { |g| { id: g.id, user_id: g.user_id, role_id: g.role_id, expires_at: g.expires_at } },
          roles: grants.map(&:role).compact.uniq.map { |r| { id: r.id, name: r.name, level: r.level } },
          organisations_users: memberships.map do |m|
            { id: m.id, user_id: m.user_id, organisation_id: m.organisation_id, status: m.status }
          end,
          organisations: memberships.map(&:organisation).compact.uniq.map do |o|
            { id: o.id, name_en: o.name_en, name_zh_tw: o.name_zh_tw }
          end
        }
      end

      def user_params
        attributes = %i[image_id first_name last_name email receive_email
                        other_phone title mobile printer_id preferred_language]
        attributes.concat([address_attributes: %i[district_id address_type]])
        attributes.concat([:disabled]) if current_user.can_disable_user?(params[:id])
        attributes.concat(%i[last_connected last_disconnected]) if User.current_user.id == params['id']&.to_i
        params.require(:user).permit(attributes)
      end

      def ids_param
        ids = params[:ids]
        return nil if ids.nil?
        return ids.split(',') if ids.is_a?(String)

        ids.map(&:to_i)
      end
    end
  end
end
