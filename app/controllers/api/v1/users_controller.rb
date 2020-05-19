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
        return search_user_and_render_json if params[:searchText].present?
        @users = @users.except_stockit_user
        @users = @users.where(id: ids_param) if ids_param.present?
        render json: @users, each_serializer: serializer
      end

      api :POST, '/v1/users', "Create user"
      def create
        save_and_render_object_with_errors(@user)
      end

      api :GET, '/v1/users/1', "List a user"
      description "Returns information about a user. Note image may be empty if user is not a reviewer."
      def show
        render json: @user, serializer: serializer
      end

      api :PUT, '/v1/users/1', "Update user"
      param :user, Hash, required: true do
        param :last_connected, String, desc: "Time when user last connected to server.", allow_nil: true
        param :last_disconnected, String, desc: "Time when user disconnected from server.", allow_nil: true
      end

      def update
        @user.update_attributes(user_params)
        if params["user"]["user_role_ids"]
          @user.create_or_remove_user_roles(params["user"]["user_role_ids"])
        end
        render json: @user, serializer: serializer
      end

      def recent_users
        @users = User.recent_orders_created_for(User.current_user.id)
        render json: @users, each_serializer: serializer
      end

      def orders_count
        render json: Order.counts_for(params[:id])
      end

      def mentionable_users
        @users = MessageService::Channel.new(app_name: app_name,
                                             messageable: Offer.find(params[:offer],
                                             is_private: params[:is_private]))
                                        .related_users
        render json: @users
      end

      private

      def serializer
        Api::V1::UserSerializer
      end

      def search_user_and_render_json
        records = @users.search({
                    search_text: params['searchText'],
                    role_name: params['role_name']}).limit(25)
        data = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "users").as_json
        render json: { "meta": {"search": params["searchText"] } }.merge(data)
      end

      def user_params
        attributes = %i[last_connected last_disconnected
        first_name last_name email receive_email other_phone title mobile printer_id]
        attributes.concat([:user_role_ids]) if User.current_user.supervisor?
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
