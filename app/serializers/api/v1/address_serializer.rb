module Api::V1

  class AddressSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :street, :flat, :building, :district_id, :addressable_id,
      :addressable_type

  end

end
