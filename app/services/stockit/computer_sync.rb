require 'stockit/base'

module Stockit
  class ComputerSync

    include Stockit::Base

    attr_accessor :computer

    def initialize(computer = nil)
      @computer = computer
    end

    class << self
      def create(computer)
        new(computer).create
      end

      def update(computer)
        new(computer).update
      end
    end

    def create
      url = url_for("/api/v1/computers")
      post(url, stockit_params)
    end

    def update
      url = url_for("/api/v1/computers/update")
      put(url, stockit_params)
    end

    private

    def stockit_params
      {
        computer: computer_params,
      }
    end

    def computer_params
      {
        brand: computer.brand,
        model: computer.model,
        serial_num: computer.serial_num,
        country_id: computer.country_id,
        size: computer.size,
        cpu: computer.cpu,
        ram: computer.ram,
        hdd: computer.hdd,
        optical: computer.optical,
        video: computer.video,
        sound: computer.sound,
        lan: computer.lan,
        wireless: computer.wireless,
        usb: computer.usb,
        comp_voltage: computer.comp_voltage,
        os: computer.os,
        os_serial_num: computer.os_serial_num,
        ms_office_serial_num: computer.ms_office_serial_num,
        mar_os_serial_num: computer.mar_os_serial_num,
        mar_ms_office_serial_num: computer.mar_ms_office_serial_num
      }
    end
  end
end
