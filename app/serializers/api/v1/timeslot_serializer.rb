module Api::V1
  class TimeslotSerializer < ApplicationSerializer
    attributes :id, :name

    def name__sql
      "name_#{current_language}"
    end
  end
end
