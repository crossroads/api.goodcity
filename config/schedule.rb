set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

every :friday, at: '12:45 am' do
  rake 'goodcity:import_swd_organisations'
end
