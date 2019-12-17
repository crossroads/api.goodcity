# rake goodcity:create_box_pallet_settings

namespace :goodcity do
  desc 'Create box pallet settings'
  task create_box_pallet_settings: :environment do
    ["stock.enable_box_pallet_creation", "stock.allow_box_pallet_item_addition"].each do |setting|
      GoodcitySetting.where(key: setting).first_or_create(
        value: "false", description: "Controls the box pallet feature"
      )
    end
  end
end
