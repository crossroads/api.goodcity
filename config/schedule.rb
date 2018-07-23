set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

every :monday, at: '11pm' do
  rake 'goodcity:import_swd_organisations'
end
