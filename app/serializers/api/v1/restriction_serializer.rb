module Api::V1
  class RestrictionSerializer < ApplicationSerializer
    attributes :id, :name_en, :name_zh_tw

    def name__sql
      "name_#{current_language}"
    end

  end
end
