namespace :goodcity do

  # rake goodcity:update_code_of_inventory_numbers
  desc 'Update code values for inventory_numbers'
  task update_code_of_inventory_numbers: :environment do
    InventoryNumber.all.each do |number|
      number.code ||= number.id.to_s.rjust(6, "0")
      number.save
    end
  end

  # rake goodcity:copy_inventory_numbers_used_in_stockit
  desc 'save stockit-inventory-numbers to inventory_numbers'
  task copy_inventory_numbers_used_in_stockit: :environment do

    inventory_numbers = Package.where("inventory_number ~ '^[0-9]'").pluck(:inventory_number)

    inventory_numbers.each do |code|
      InventoryNumber.where(code: code).first_or_create
    end
  end

end
