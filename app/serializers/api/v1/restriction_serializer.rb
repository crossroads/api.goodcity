module Api::V1
  class RestrictionSerializer < ApplicationSerializer
    attributes :id, :name

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
