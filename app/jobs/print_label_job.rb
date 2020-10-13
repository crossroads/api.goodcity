class PrintLabelJob < ActiveJob::Base
  def perform(package_id, current_user_id, opts={})
    package = Package.find(package_id)
    options = { inventory_number: package.inventory_number, print_count: opts[:print_count] }
    label = "Labels::#{opts[:label_type].classify}".safe_constantize.new(options)
    printer = PrintersUser.where(user_id: current_user_id, tag: opts[:tag]).first.try(:printer)
    PrintLabel.new(printer, label).print
  end
end
