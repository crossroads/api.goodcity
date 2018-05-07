module Api::V1
  class TimeslotSerializer < ApplicationSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :name

    def name__sql
      "name_#{current_language}"
    end
  end
end
