class PrintLabel
  attr_accessor :printer, :label

  def initialize(printer, label)
    @printer = printer
    @label = label
    @file = nil
  end

  def print
    print_id, errors, status = Open3.capture3(print_options, Rails.root.join("app", "services", "barcode_service.exp").to_s)
    log(print_id, errors, status)
    @file.delete
    return print_id, errors, status
  end

  private

  def print_file
    @file = Tempfile.new("cupsjob")
    @file.write(@label.to_s)
    @file.close
    @file
  end

  def print_options
    {
      "NAME" => @printer.name,
      "HOST" => @printer.host,
      "USER" => @printer.username,
      "PWD"  => @printer.password,
      "FILE" => print_file.path
    }
  end

  def log(print_id, errors, status)
    log_hash = {
      printer_name: print_options['NAME'],
      printer_host: print_options['HOST'],
      printer_user: print_options['USER'],
      print_job_id: print_id,
      print_job_errors: errors,
      print_job_status: status
    }
    Rails.logger.info(log_hash)
    puts log_hash
  end

end
