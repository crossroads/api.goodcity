module Api::V1
  class AddressSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :street, :flat, :building, :district_id, :addressable_id,
               :addressable_type, :notes
    has_one :district, serializer: DistrictSerializer
  end
end
