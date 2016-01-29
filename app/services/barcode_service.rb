require 'easyzpl'
require 'open3'

class BarcodeService
  def print(inventory_number)
    # There are 72 dots in an inch (usually)
    # In the case of our printer, there are 203
    dots = 300

    # The dimensions of the label
    label_width              = 2
    label_height             = 1
    label_fields_orientation = :landscape

    # print settings
    printer_name = Rails.application.secrets.barcode['printer_name']
    printer_host = Rails.application.secrets.barcode['printer_host']

    # Generate the new label
    label = Easyzpl::Label.new( dots: dots,
                                width: label_width,
                                field_orientation: label_fields_orientation,
                                height: label_height )

    label.home_position(30, 30)

    label.bar_code_qr( 'https://redirect.crossroads.org.hk/inventory?num=' + inventory_number,
                       0,
                       0.05,
                       :error_correction => :ultra,
                       :magnification    => 5 )

    label.reset_barcode_fields_to_default

    label.bar_code_128( inventory_number,
                        0.8,
                        0.4,
                        :orientation => :landscape,
                        :check_digit => :true,
                        :mode        => :auto,
                        :height      => 0.4 )

    label.text_field( inventory_number,
                      0.8,
                      0.05,
                      :orientation => :landscape,
                      :width       => 0.3,
                      :height      => 0.4 )

    # Generate the label code (returns print_id, errors, status)
    Open3.capture3("lp -h #{printer_host} -d #{printer_name} -o raw", stdin_data: label.to_s)
  end
end
