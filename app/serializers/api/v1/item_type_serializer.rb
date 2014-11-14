module Api::V1

  class ItemTypeSerializer < CachingSerializer
    embed :ids, include: true
    attributes :id, :name, :code
  end

end
