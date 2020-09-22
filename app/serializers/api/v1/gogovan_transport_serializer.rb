module Api::V1
  class GogovanTransportSerializer < ApplicationSerializer
    attributes :id, :disabled, :name

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
