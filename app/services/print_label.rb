class PrintLabel
  attr_accessor :printer, :label

  def initialize(printer, label_file)
    @printer = printer
    @label_file   = label
  end

  def print
    print_id, errors, status = Open3.capture3(options, Rails.root.join("app", "services", "barcode_service.exp").to_s)

    log_hash = { printer_name: "\"#{options["NAME"]}\"",
            printer_host: "\"#{options["HOST"]}\"",
            printer_user: "\"#{options["USER"]}\"",
            # print_job_id: "\"#{print_id}\"",
            print_job_errors: "\"#{errors}\"",
            print_job_status: "\"#{status}\"",
            class: self.class.name }
    Rails.logger.info(log_hash)

    label_file.delete

    return print_id, errors, status
  end

  private

  def print_options
    barcode = Rails.application.secrets.barcode
    {
      "NAME" => barcode["printer_name"],
      "HOST" => barcode["printer_host"],
      "USER" => barcode["printer_user"],
      "PWD" => barcode["printer_pwd"],
      "FILE" => @label_file.path,
    }
  end
end
