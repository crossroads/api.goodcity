FactoryBot.define do
  factory :crossroads_transport do
    sequence(:name_en) { |n| seq.keys.sort[n%seq.keys.size] }
    name_zh_tw         { seq[name_en][:name_zh_tw] }
    cost               { seq[name_en][:cost] }
    truck_size         { seq[name_en][:truck_size] }
    is_van_allowed     { seq[name_en][:is_van_allowed] }
    initialize_with    { CrossroadsTransport.find_or_initialize_by(name_en: name_en) } # avoid duplicates

    transient do
      seq { @crossroads_transport ||= YAML.load_file("#{Rails.root}/db/crossroads_transports.yml") }
    end
  end
end
