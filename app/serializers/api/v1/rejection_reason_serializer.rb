module Api::V1
  class RejectionReasonSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
