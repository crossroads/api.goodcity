module Api::V1
  class CrossroadsTransportSerializer < ApplicationSerializer
    attributes :id, :cost, :is_van_allowed
    attribute "name_#{current_language}".to_sym
  end
end
