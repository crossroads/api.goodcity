module Api::V1

  class DistrictSerializer < ActiveModel::Serializer
    cached
    delegate :cache_key, to: :object

    embed :ids, include: true
    attributes :id, :name, :territory_id

    def name
      Rails.logger.info("district hit: #{cache_key}")
      object.name
    end
  end

end
