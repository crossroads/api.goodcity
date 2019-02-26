module Api::V1
  class ProcessChecklistSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :text, :booking_type_id

    def text__sql
      "text_#{current_language}"
    end
  end
end
