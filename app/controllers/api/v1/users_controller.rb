require "goodcity/user_utils"

module Api
  module V1
    class UsersController < Api::V1::ApiController
      load_and_authorize_resource :user, parent: false
      skip_load_resource :user, :only => [:orders_count]

      resource_description do
        short 'List Users'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/users', "List all users"
      param :ids, Array, desc: "Filter by user ids e.g. ids = [1,2,3,4]"
      description <<-EOS
        Note: in accordance with permissions, users will only be able to list users they are allowed to see.
        For a donor, this will be just themselves. For administrators, this will be all users.
      EOS
      def index
        @users = @users.except_stockit_user
        return search_user_and_render_json if params[:searchText].present?

        @users = @users.with_roles(params[:roles]) if params[:roles].present?
        @users = @users.where(id: ids_param) if ids_param.present?
        render json: @users.with_eager_loading, each_serializer: serializer
      end

      api :POST, '/v1/users', "Create user"
      def create
        @user.assign_attributes(user_params)

        if @user.save
          if params["user"]["organisations_users_ids"].present?
            @user.organisations << Organisation.find_by(id: params["user"]["organisations_users_ids"])
          end

          render json: @user, serializer: serializer, include_user_roles: true, status: 201
        else
          render_error(@user.errors.full_messages.join(". "))
        end
      end

      api :GET, '/v1/users/1', "List a user"
      description "Returns information about a user. Note image may be empty if user is not a reviewer."
      def show
        render json: @user, serializer: Api::V1::UserDetailsSerializer, root: 'user'
      end

      api :PUT, '/v1/users/1', "Update user"
      param :user, Hash, required: true do
        param :last_connected, String, desc: "Time when user last connected to server.", allow_nil: true
        param :last_disconnected, String, desc: "Time when user disconnected from server.", allow_nil: true
      end

      def update
        @user.update(user_params)
        if @user.valid?
          render json: @user, serializer: serializer
        else
          render_error(@user.errors.full_messages.join(". "))
        end
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

      api :PUT, '/v1/merge_users', "Merge one user details into another user"
      param :master_user_id, String, desc: "Id of user in which other user will be merged"
      param :merged_user_id, String, desc: "Id of user which needs to be merged and removed."
      def merge_users
        merge_response = Goodcity::UserUtils.merge_user!(params[:master_user_id], params[:merged_user_id])

        if merge_response[:error]
          render json: merge_response, status: 422
        else
          render json: merge_response[:user], serializer: serializer
        end
      end

      private

      def serializer
        Api::V1::UserSerializer
      end

      def search_user_and_render_json
        records = @users.limit(25)
        records = records.filter_users(params)

        data = ActiveModel::ArraySerializer.new(records,
          each_serializer: Api::V1::UserDetailsSerializer,
          include_user_roles: true,
          root: 'users'
        ).as_json
        render json: { 'meta': { 'search': params['searchText'] } }.merge(data)
      end

      def user_params
        attributes = %i[image_id first_name last_name email receive_email
          other_phone title mobile printer_id preferred_language]
        attributes.concat([address_attributes: [:district_id, :address_type]])
        attributes.concat([:disabled]) if current_user.can_disable_user?(params[:id])
        attributes.concat([:last_connected, :last_disconnected]) if User.current_user.id == params["id"]&.to_i
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
