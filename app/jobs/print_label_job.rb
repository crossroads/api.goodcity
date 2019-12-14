class PrintLabelJob < ActiveJob::Base
  def perform(package_id, current_user_id, label_type, print_count)
    package = Package.find(package_id)
    options = { inventory_number: package.inventory_number, print_count: print_count }
    label = "Label::#{label_type.classify}".safe_constantize.new(options)
    printer = User.find_by_id(current_user_id).try(:printer)
    PrintLabel.new(printer, label).print
  end
end
