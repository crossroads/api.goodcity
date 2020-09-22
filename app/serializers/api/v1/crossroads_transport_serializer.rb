module Api::V1
  class CrossroadsTransportSerializer < ApplicationSerializer
    attributes :id, :cost, :is_van_allowed, :name

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
