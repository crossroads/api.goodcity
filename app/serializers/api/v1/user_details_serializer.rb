module Api::V1
  class UserDetailsSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name, :mobile, :title,
      :created_at, :last_connected, :last_disconnected, :email,
      :is_email_verified, :is_mobile_verified, :disabled, :preferred_language

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer
    has_many :printers_users, serializer: PrintersUserSerializer
    has_many :user_roles, serializer: UserRoleSerializer
    has_many :organisations_users, serializer: OrganisationsUserSerializer

    def include_attribute?
      return !@options[:user_summary] unless @options[:user_summary].nil?
      (User.current_user.try(:staff?) || User.current_user.try(:id) == id)
    end

    alias_method :include_address?, :include_attribute?
    alias_method :include_mobile?, :include_attribute?
    alias_method :include_email?, :include_attribute?
    alias_method :include_last_connected?, :include_attribute?
    alias_method :include_last_disconnected?, :include_attribute?
  end
end
