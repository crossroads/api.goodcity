namespace :goodcity do
  # rake goodcity:create_restrictions
  desc 'Add Purposes list'
  task create_restrictions: :environment do
    restrictions = YAML.load_file("#{Rails.root}/db/restrictions.yml")
    restrictions.each_value do |record|
      Restriction.find_or_create_by(record)
    end
  end

  # rake goodcity:update_restrictions
  desc 'Update Chinese Translation in Purposes list'
  task update_restrictions: :environment do
    restrictions = YAML.load_file("#{Rails.root}/db/restrictions.yml")
    restrictions.each_value do |record|
      Restriction.where(name_en: record[:name_en]).update(name_zh_tw: record[:name_zh_tw])
    end
  end

end
