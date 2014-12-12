module Api::V1

  class DistrictSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :territory_id

    def name__sql
      "name_#{I18n.locale}"
    end
  end

end
