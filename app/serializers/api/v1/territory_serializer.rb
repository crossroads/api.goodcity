module Api::V1

  class TerritorySerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name

    has_many :districts, serializer: DistrictSerializer

    def name__sql
      "name_#{I18n.locale}"
    end
  end

end
