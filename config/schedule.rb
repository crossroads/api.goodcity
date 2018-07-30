set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

every :friday, at: '5 pm' do
  rake 'goodcity:import_swd_organisations'
end
