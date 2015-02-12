module Api::V1

  class DistrictSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :territory_id

    def name__sql
      "name_#{current_language}"
    end
  end

end
