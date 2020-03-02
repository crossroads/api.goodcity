# rake goodcity:add_new_cancellation_reasons
namespace :goodcity do
  desc 'Add new roles'
  task add_new_cancellation_reasons: :environment do
    order_reasons = YAML.load_file("#{Rails.root}/db/order_cancellation_reasons.yml")

    order_reasons.each_value do |reason|
      CancellationReason.where(name_en: reason[:name_en]).first_or_create(reason)
    end
  end
end
