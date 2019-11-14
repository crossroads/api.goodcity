# rake goodcity:create_dummy_package_details

namespace :goodcity do
  desc 'Add dummy package detail data'
  task create_dummy_package_details: :environment do
    %w[computer_accessories computers electricals].each do |table_name|
      details = YAML.load_file("#{Rails.root}/db/#{table_name}.yml")
      details.each do |detail|
        klass = table_name.classify.safe_constantize
        detail_attributes = detail.second
        klass.create(detail_attributes)
      end
    end
  end
end
