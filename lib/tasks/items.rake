namespace :goodcity do

  # rake goodcity:update_items_saleable_field
  desc 'Update saleable field of all items'
  task update_items_saleable_field: :environment do
    Offer.find_in_batches(batch_size: 10).each do |offers|
      offers.each do |offer|
        saleable_value = offer.items.order(:id).first.try(:saleable)
        offer.items.update_all(saleable: saleable_value)
        puts "Update items from Offer #{offer.id}."
      end
    end
  end
end
