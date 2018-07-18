set :output, 'log/cron_log.log'

# every :sunday, at: '12am' do
#   rake 'goodcity:import_swd_organisations'
# end

every 5.minutes do
  rake 'goodcity:import_swd_organisations'
end
