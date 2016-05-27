module Api::V1::Stockit
  class CodeSerializer < ApplicationSerializer
    attributes :id, :description

    def description__sql
      "description_en"
    end

    def description
      object.description_en
    end
  end
end
