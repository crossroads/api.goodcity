class PrintLabel
  attr_accessor :printer, :label_file

  def initialize(label_file, current_user_id)
    @printer     = User.find_by_id(current_user_id).try(:printer)
    @label_file  = label_file
  end

  def print
    print_id, errors, status = Open3.capture3(print_options, Rails.root.join("app", "services", "barcode_service.exp").to_s)

    log_hash = {
      printer_name: print_options['NAME'],
      printer_host: print_options['HOST'],
      printer_user: print_options['USER'],
      print_job_errors: errors,
      print_job_status: status,
      class: self.class.name
    }

    Rails.logger.info(log_hash)

    label_file.delete

    return print_id, errors, status
  end

  private

  def print_options
    {
      "NAME" => printer.name,
      "HOST" => printer.host,
      "USER" => printer.username,
      "PWD" => printer.password,
      "FILE" => label_file.path
    }
  end
end
