module Api::V1

  class ItemTypeSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name, :code

    def name__sql
      "name_#{I18n.locale}"
    end
  end

end
