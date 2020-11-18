# frozen_string_literal: true

# rails goodcity:preload_canned_responses
namespace :goodcity do
  task preload_canned_responses: :environment do
    CannedResponse.destroy_all
    count = 0
    canned_responses = YAML.load_file("#{Rails.root}/db/canned_responses.yml")
    canned_responses.each do |_k, v|
      canned_response = CannedResponse.new(v)
      if canned_response.save
        count += 1
      else
        puts "Error while creating #{v} \n Error: #{canned_response.errors.full_messages}"
      end
    end
    puts "Succesfully created #{count} records"
  end
end
