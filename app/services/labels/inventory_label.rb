module Labels
  class InventoryLabel < BaseLabel
    
    attr_accessor :options
    
    #
    # InventoryLabel.new(inventory_number: "F12345", print_count: 2)
    def initialize(options={})
      @options = default_options.merge(options)
      super(@options)
    end

    def default_options
      { 
        dots: 300,
        width: 2,
        height: 1,
        field_orientation: :landscape,
        barcode_qr_url: "https://redirect.crossroads.org.hk/inventory?num=".freeze
      }
    end

    private

    def draw
      super
      @label.home_position(30, 30)

      @label.bar_code_qr(@options[:barcode_qr_url] + @options[:inventory_number],
                        0,
                        0.05,
                        error_correction: :ultra,
                        magnification: 5)

      @label.reset_barcode_fields_to_default

      @label.bar_code_128("X" + @options[:inventory_number],
                          0.8,
                          0.4,
                          orientation: :landscape,
                          check_digit: true,
                          mode: :auto,
                          height: 0.4)

      @label.text_field(@options[:inventory_number],
                        0.8,
                        0.05,
                        orientation: :landscape,
                        width: 0.3,
                        height: 0.4)
    end
  end
end
