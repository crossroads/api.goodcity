module Api::V1

  class UserSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :first_name, :last_name, :mobile, :message_ids

    has_many :permissions, serializer: PermissionSerializer
    has_one :address, serializer: AddressSerializer

    def mobile
      object.try(:mobile) && object.mobile.slice!(4..-1)
    end

    def message_ids
      object.messages.pluck(:id) + object.sent_messages.pluck(:id)
    end
  end

end
