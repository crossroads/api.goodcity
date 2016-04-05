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

    label.bar_code_128( 'X' + inventory_number,
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

    # generate label and save to temp file
    f = Tempfile.new("cupsjob")
    f.write label.to_s
    f.close

    # Print label
    barcode = Rails.application.secrets.barcode
    options = {
      'NAME' => barcode['printer_name'],
      'HOST' => barcode['printer_host'],
      'USER' => barcode['printer_user'],
      'PWD' => barcode['printer_pwd'],
      'FILE' => f.path
    }

    print_id, errors, status = Open3.capture3(options, Rails.root.join('app', 'services', 'barcode_service.exp').to_s)
    
    log_hash = { printer_name: "\"#{options['NAME']}\"",
        printer_host: "\"#{options['HOST']}\"",
        printer_user: "\"#{options['USER']}\"",
        # print_job_id: "\"#{print_id}\"",
        print_job_errors: "\"#{errors}\"",
        print_job_status: "\"#{status}\""
    }
    Rails.logger.info(log_hash.collect{|k,v| "#{k}=#{v}"}.join(" "))

    f.delete

    return print_id, errors, status
  end
end
