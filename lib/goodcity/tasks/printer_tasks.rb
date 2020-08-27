class PrinterTasks
  def self.initialize_printers_users!
    User.where('printer_id IS NOT NULL').find_each do |user|
      PrintersUser.first_or_create(user: user, printer_id: user.printer_id, tag: "stock")
    end
  end
end