# frozen_string_literal: true

module Api
  module V1
    # Serializer for medical
    class MedicalSerializer < ApplicationSerializer
      embed :ids, include: true

      attributes :id, :brand, :serial_number, :country_id,
                 :updated_by_id, :model

      has_one :country, serializer: CountrySerializer

      def include_country?
        @options[:include_country]
      end
    end
  end
end
