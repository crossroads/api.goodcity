namespace :goodcity do
  # rake goodcity:create_lookups
  desc "Add dummy package detail data"
  task create_lookups: :environment do
    lookups = YAML.load_file("#{Rails.root}/db/lookup.yml")
    lookups.each do |lookup|
      Lookup.where(name: lookup["name"], label_en: lookup["label_en"]).first_or_create(lookup)
    end
  end
end
