require 'stockit/base'

module Stockit
  class ComputerAccessorySync

    include Stockit::Base

    attr_accessor :computer_accessory

    def initialize(computer_accessory = nil)
      @computer_accessory = computer_accessory
    end

    class << self
      def create(computer_accessory)
        new(computer_accessory).create
      end

      def update(computer_accessory)
        new(computer_accessory).update
      end
    end

    def create
      url = url_for("/api/v1/computer_accessories")
      post(url, stockit_params)
    end

    def update
      url = url_for("/api/v1/computer_accessories/update")
      put(url, stockit_params)
    end

    private

    def stockit_params
      {
        computer_accessory: computer_accessory_params,
      }
    end

    def computer_accessory_params
      {
        brand: computer_accessory.brand,
        model: computer_accessory.model,
        serial_number: computer_accessory.serial_number,
        country_id: computer_accessory.country_id,
        size: computer_accessory.size,
        interface: computer_accessory.interface,
        comp_test_status: computer_accessory.comp_test_status
      }
    end
  end
end
