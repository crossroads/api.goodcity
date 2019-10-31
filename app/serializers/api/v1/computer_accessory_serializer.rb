module Api
  module V1
    class ComputerAccessorySerializer < ApplicationSerializer
      embed :ids, include: true
      attributes :id, :brand, :model, :serial_num, :country_id, :size,
        :interface, :comp_voltage, :comp_test_status, :updated_by_id

      has_one :country, serializer: CountrySerializer

      def include_country?
        @options[:include_country]
      end
    end
  end
end
