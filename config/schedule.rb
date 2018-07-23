set :output, 'log/cron_log.log'

every :monday, at: '7pm' do
  rake 'goodcity:import_swd_organisations'
end
