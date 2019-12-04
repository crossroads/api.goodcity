class PrintLabelJob < ActiveJob::Base
  def perform(package_id, printer_id, label_type, print_count)
    printer     = Printer.find(printer_id)
    package     = Package.find(package_id)
    label       = "Label::#{label_type.classify}".safe_constantize.new(
      package.inventory_number, print_count).label_to_print
    PrintLabel.new(printer, label).print
  end
end
