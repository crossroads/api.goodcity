# frozen_string_literal: true

module Api
  module V1
    # Serielizer for medical
    class MedicalSerializer < ApplicationSerializer
      embed :ids, include: true

      attributes :id, :brand, :serial_number, :country_id,
                 :expiry_date, :updated_by_id

      has_one :country, serilizer: CountrySerializer

      def include_country?
        @options[:include_country]
      end
    end
  end
end
