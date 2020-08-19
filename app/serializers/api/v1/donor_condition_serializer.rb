module Api::V1
  class DonorConditionSerializer < ApplicationSerializer
    attributes :id, :visible_to_donor
    attribute "name_#{current_language}".to_sym
  end
end
