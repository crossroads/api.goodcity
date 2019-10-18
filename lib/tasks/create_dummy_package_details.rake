namespace :goodcity do
  # rake goodcity:create_dummy_package_details
  desc 'Add dummy package detail data'
  task create_dummy_package_details: :environment do
    details = YAML.load_file("#{Rails.root}/db/dummy_package_detail.yml")
    details.each do |detail|
      klass = detail.first.classify.safe_constantize
      detail_attributes = detail.second
      klass.create(detail_attributes)
    end
  end
end
