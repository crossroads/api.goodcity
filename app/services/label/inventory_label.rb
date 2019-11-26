module Label
  class InventoryLabel < BaseLabel
    attr_accessor :inventory_number, :label

    BARCODE_QR_URL = "https://redirect.crossroads.org.hk/inventory?num="

    def initialize(inventory_number)
      @inventory_number = inventory_number
      @label            = BaseLabel.new(INVENTORY_LABEL_DOTS,
                          INVENTORY_LABEL_WIDTH, INVENTORY_LABEL_FIELD_ORIENTATION, INVENTORY_LABEL_HEIGHT).initialize_label
    end

    def design_label
      label.home_position(30, 30)

      label.bar_code_qr(BARCODE_QR_URL + inventory_number, 0,
        0.05, :error_correction => :ultra, :magnification => 5)

      label.reset_barcode_fields_to_default


      label.bar_code_128("X" + inventory_number,
                        0.8,
                        0.4,
                        :orientation => :landscape,
                        :check_digit => :true,
                        :mode => :auto,
                        :height => 0.4)

      label.text_field(inventory_number,
                      0.8,
                      0.05,
                      :orientation => :landscape,
                      :width => 0.3,
                      :height => 0.4)
    end
  end
end
