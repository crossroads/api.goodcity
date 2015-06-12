module Api::V1

  class UserSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true
    attributes :id, :first_name, :last_name, :permission_id, :mobile,
      :created_at, :last_connected, :last_disconnected

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer

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
