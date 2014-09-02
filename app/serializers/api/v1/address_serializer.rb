module Api::V1

  class AddressSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :street, :flat, :building
  end

end
