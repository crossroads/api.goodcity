require 'stockit/base'

module Stockit
  class ElectricalSync

    include Stockit::Base

    attr_accessor :electrical

    def initialize(electrical = nil)
      @electrical = electrical
    end

    class << self
      def create(electrical)
        new(electrical).create
      end

      def update(electrical)
        new(electrical).update
      end
    end

    def create
      url = url_for("/api/v1/electricals")
      post(url, stockit_params)
    end

    def update
      url = url_for("/api/v1/electricals/update")
      put(url, stockit_params)
    end

    private

    def stockit_params
      {
        electrical: electrical_params,
      }
    end

    def electrical_params
      {
        brand: electrical.brand,
        model: electrical.model,
        serial_number: electrical.serial_number,
        country_id: electrical.country_id,
        standard: electrical.standard,
        voltage: electrical.voltage,
        frequency: electrical.frequency,
        power: electrical.power,
        system_or_region: electrical.system_or_region,
        test_status: electrical.test_status,
        tested_on: electrical.tested_on
      }
    end
  end
end
