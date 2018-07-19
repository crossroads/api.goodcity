set :output, 'log/cron_log.log'

every :sunday, at: '12am' do
  rake 'goodcity:import_swd_organisations'
end
