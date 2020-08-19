module Api::V1
  class GogovanTransportSerializer < ApplicationSerializer
    attributes :id, :disabled
    attribute "name_#{current_language}".to_sym
  end
end
