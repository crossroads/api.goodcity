namespace :goodcity do

  # rake goodcity:modify_ggv_transport_options
  desc 'Modify GGV transport options'
  task modify_ggv_transport_options: :environment do
    GogovanTransport.create(
      name_en: "9 Tonne Truck",
      name_zh_tw: "9噸卡車"
    )

    option = GogovanTransport.find_by(name_en: "5.5t Truck")
    option.update_column(:name_en, "5.5 Tonne Truck")
  end
end
