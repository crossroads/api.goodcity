module Api::V1

  class CrossroadsTransportSerializer < ActiveModel::Serializer
    attributes :id, :name, :cost

    def name__sql
      "name_#{I18n.locale}"
    end
  end

end
