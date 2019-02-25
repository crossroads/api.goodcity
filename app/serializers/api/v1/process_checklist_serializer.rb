module Api::V1
  class ProcessChecklistSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :text, :booking_type_id
  end
end
