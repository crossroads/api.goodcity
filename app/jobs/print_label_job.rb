class PrintLabelJob < ActiveJob::Base
  def perform(package_id, current_user_id, label_type, print_count)
    package     = Package.find(package_id)
    label       = "Label::#{label_type.classify}".safe_constantize.new(
      package.inventory_number, print_count).label_to_print
    PrintLabel.new(label, current_user_id).print
  end
end
