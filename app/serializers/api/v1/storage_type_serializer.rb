module Api
  module V1
    class StorageTypeSerializer < ApplicationSerializer
      embed :ids, include: true
      attributes :id, :name
    end
  end
end
