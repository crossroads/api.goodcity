module Api::V1
  class GogovanTransportSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name, :disabled

    def name__sql
      "name_#{current_language}"
    end
  end
end
