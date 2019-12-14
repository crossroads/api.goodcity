class PrintLabel
  attr_accessor :printer, :label

  def initialize(printer, label)
    @printer = printer
    @label = label
  end

  def print
    print_id, errors, status = Open3.capture3(print_options, Rails.root.join("app", "services", "barcode_service.exp").to_s)
    log(errors, status)
    @label.delete
    return print_id, errors, status
  end

  private

  def print_options
    {
      "NAME" => printer.name,
      "HOST" => printer.host,
      "USER" => printer.username,
      "PWD" => printer.password,
      "FILE" => @label.to_file.path
    }
  end

  def log(errors, status)
    log_hash = {
      printer_name: print_options['NAME'],
      printer_host: print_options['HOST'],
      printer_user: print_options['USER'],
      print_job_errors: errors,
      print_job_status: status,
      class: self.class.name
    }
    Rails.logger.info(log_hash)
  end

end
