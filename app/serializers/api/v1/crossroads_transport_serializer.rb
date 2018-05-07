module Api::V1
  class CrossroadsTransportSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name, :cost, :is_van_allowed

    def name__sql
      "name_#{current_language}"
    end
  end
end
