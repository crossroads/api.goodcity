module Api::V1
  class CancellationReasonSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    embed :ids, include: true
    attributes :id, :name

    def name__sql
      "name_#{current_language}"
    end
  end
end
