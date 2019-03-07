module Api::V1
  class UserSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true
    attributes :id, :first_name, :last_name, :mobile, :title,
      :created_at, :last_connected, :last_disconnected, :email, :user_roles_ids, :organisations_users_ids

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer

    def user_roles_ids
      object.user_roles.pluck(:id)
    end

    def organisations_users_ids
      object.organisations_users.pluck(:id)
    end

    def user_roles_ids__sql
      "coalesce((select array_agg(user_roles.id) from user_roles where
        user_id = users.id), '{}'::int[])"
    end

    def organisations_users_ids__sql
      "coalesce((select array_agg(organisations_users.id) from organisations_users where
        user_id = users.id), '{}'::int[])"
    end

    def include_attribute?
      return !@options[:user_summary] unless @options[:user_summary].nil?
      (User.current_user.try(:staff?) || User.current_user.try(:id) == id)
    end
    alias_method :include_address?, :include_attribute?
    alias_method :include_mobile?, :include_attribute?
    alias_method :include_last_connected?, :include_attribute?
    alias_method :include_last_disconnected?, :include_attribute?
  end
end
