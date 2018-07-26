set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

every :thursday, at: '11 pm' do
  rake 'goodcity:import_swd_organisations'
end
