require 'easyzpl'
require 'open3'

module Label
  class BaseLabel
    attr_accessor :dots, :width, :field_orientation, :height, :file

    def initialize(dots, width, field_orientation, height)
      @dots              = dots
      @width             = width
      @field_orientation = field_orientation
      @height            = height
    end

    def initialize_label
      Easyzpl::Label.new(dots: dots, width: label_width, field_orientation: label_fields_orientation,
        height: label_height)
    end

    def tmp_label_file(label)
      @file = Tempfile.new("cupsjob")
      @file.write label.to_s
      @file.close
    end

    private

    def log_details(errors, status)
      log_hash = {
        printer_name: "\"#{print_options["NAME"]}\"",
        printer_host: "\"#{print_options["HOST"]}\"",
        printer_user: "\"#{print_options["USER"]}\"",
        # print_job_id: "\"#{print_id}\"",
        print_job_errors: "\"#{errors}\"",
        print_job_status: "\"#{status}\"",
        class: self.class.name
      }
      Rails.logger.info(log_hash)
    end
  end
end

