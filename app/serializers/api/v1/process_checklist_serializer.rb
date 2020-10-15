module Api::V1
  class ProcessChecklistSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :text, :booking_type_id

    def text
      object.try("text_#{current_language}".to_sym)
    end
  end
end
