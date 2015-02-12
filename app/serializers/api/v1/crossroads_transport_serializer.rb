module Api::V1

  class CrossroadsTransportSerializer < ApplicationSerializer
    attributes :id, :name, :cost

    def name__sql
      "name_#{current_language}"
    end
  end

end
