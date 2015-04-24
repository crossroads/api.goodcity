module Api::V1

  class UserSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :first_name, :last_name, :permission_id, :mobile,
      :created_at

    has_one :image, serializer: ImageSerializer
    has_one :address, serializer: AddressSerializer

    def include_mobile?
      User.current_user.try(:permission).try(:present?)
    end
    alias_method :include_address?, :include_mobile?

  end

end
