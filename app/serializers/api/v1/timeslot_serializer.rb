module Api::V1
  class TimeslotSerializer < ActiveModel::Serializer
    attributes :id, :name

    def name__sql
      "name_#{I18n.locale}"
    end
  end
end
