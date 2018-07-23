set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

every :tuesday, at: '12am' do
  rake 'goodcity:import_swd_organisations'
end
