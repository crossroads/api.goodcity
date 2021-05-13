class PrintLabelJob < ActiveJob::Base
  def perform(package_id, printer_id, opts = {})
    package = Package.find(package_id)
    options = { inventory_number: package.inventory_number, print_count: opts[:print_count] }
    label = "Labels::#{opts[:label_type].classify}".safe_constantize.new(options)
    printer = Printer.find(printer_id)
    PrintLabel.new(printer, label).print
  end
end
