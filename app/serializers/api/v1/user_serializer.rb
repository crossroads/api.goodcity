module Api::V1

  class UserSerializer < ApplicationSerializer
    include SerializeTimeValue

    embed :ids, include: true
    attributes :id, :first_name, :last_name, :permission_id, :mobile,
      :created_at, :last_connected, :last_disconnected

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer

    def include_attribute?
      User.current_user.try(:permission).try(:present?)
    end
    alias_method :include_address?, :include_attribute?
    alias_method :include_mobile?, :include_attribute?
    alias_method :include_last_connected?, :include_attribute?
    alias_method :include_last_disconnected?, :include_attribute?

  end

end
