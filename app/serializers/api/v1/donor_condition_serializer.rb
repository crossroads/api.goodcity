module Api::V1
  class DonorConditionSerializer < ApplicationSerializer
    attributes :id, :visible_to_donor, :name

    def name
      object.try("name_#{current_language}".to_sym)
    end
  end
end
