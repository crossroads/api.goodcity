module Api
  module V1
    class ElectricalSerializer < ApplicationSerializer
      embed :ids, include: true

      attributes :id, :brand, :model, :serial_number, :country_id, :standard,
        :voltage, :frequency, :power, :system_or_region, :test_status,
        :tested_on, :updated_by_id, :test_status_id, :voltage_id, :frequency_id

      has_one :country, serializer: CountrySerializer

      def include_country?
        @options[:include_country]
      end
    end
  end
end
