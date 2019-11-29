class PrintInventoryLabelJob < ActiveJob::Base
  def perform(package_id, printer_id, label_type)
    printer = Printer.find(printer_id)
    package = Package.find(package_id)
    label = InventoryLabel.new(package.inventory_number).label_to_print
    PrintLabel.new(printer, label).print
  end
end
