module Api::V1

  class RejectionReasonSerializer < ActiveModel::Serializer
    embed :ids, include: true
    attributes :id, :name

    def name__sql
      "name_#{I18n.locale}"
    end
  end

end
