module Api::V1
  class IdentityTypeSerializer < ApplicationSerializer
    attribute "name_#{current_language}".to_sym
  end
end
