require 'factory_bot'
require 'goodcity/demo_data'

#
# Make sure to run rake db:seed first
#    rake db:seed db:demo MULTIPLE=100
#
namespace :db do

  desc 'Create demo data. Specify multiple with MULTIPLE=42 rake db:demo. Run rake db:seed first.'
  task demo: :environment do
    abort("This job is not designed to be run in production mode. Aborting!") if Rails.env.production?

    # Specify number of test cases to produce
    multiple = ENV['MULTIPLE'].to_i # Note: nil.to_i = 0
    multiple = (multiple > 0) ? multiple : 1
    puts "Generating demo data. MULTIPLE=#{multiple}"
    Goodcity::DemoData.new(multiple: multiple).generate!
  end

end
