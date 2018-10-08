module Api::V1
  class IdentityTypeSerializer < ApplicationSerializer
    attributes :id, :name

    def name__sql
      "name_#{current_language}"
    end
    
  end
end
