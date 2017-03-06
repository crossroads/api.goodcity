#use 'rake populate_organisation:organisation' to create or update organisation details
namespace :populate_organisation do
  task organisation:  :environment do
    organisation_hash = {
      "name_en" => "name_en",
      "name_zh_tw" => "name_zh",
      "website" => "url",
    }
    # Nestful.get("https://raw.githubusercontent.com/crtr0/twilio-rails-demo/master/app/controllers/twilio_controller.rb").response.body
    JSON.parse(File.read('app/assets/organisation.json')).each do |data|
      organisation_hash =  organisation_hash.keep_if { |k, v| data.key? v }
      organisation = Organisation.find_by(registration: data['org_id']) || Organisation.new(registration: data['org_id'])
        organisation_hash.each do |organisation_column, data_key|
          if (organisation.try(organisation_column) != data[data_key])
            puts data
            puts organisation
            organisation[organisation_column.to_sym] = data[data_key]
          end
        end
       organisation.save
    end
  end
end
