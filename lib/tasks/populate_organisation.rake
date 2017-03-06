#use 'rake populate_organisation:organisation' to create or update organisation details
namespace :populate_organisation do
  task organisation:  :environment do
    # Nestful.get("https://raw.githubusercontent.com/crtr0/twilio-rails-demo/master/app/controllers/twilio_controller.rb").response.body
    JSON.parse(File.read('app/assets/organisation.json')).each do |data|
      organisation = Organisation.find_by(registration: data['org_id'])
     if (organisation)
        organisation_hash = {
          "name_en" => "name_en",
          "url" => "website"
        }
        organisation_hash.each do |key, val|
          if (organisation.try(key) != data[val])
            organisation.instance_variable_set(key, data[val])
          end
        end
       organisation.save
      else
        Organisation.create(website: data["url"], name_en: data["name_en"] ,
                            registration: data["org_id"])
        # puts "Organisation.last"
      end
    end
  end
end
