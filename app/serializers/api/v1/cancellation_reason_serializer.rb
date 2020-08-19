module Api::V1
  class CancellationReasonSerializer < ApplicationSerializer
    embed :ids, include: true
    attribute :id
    attribute "name_#{current_language}".to_sym
  end
end
