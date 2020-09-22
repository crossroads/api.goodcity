module Api::V1
  class RestrictionSerializer < ApplicationSerializer
    attributes :id, :name_en, :name_zh_tw

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
