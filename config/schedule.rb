set :output, 'log/cron_log.log'
set :environment, ENV['RAILS_ENV']

# Note: times are in UTC as our production/staging servers are in UTC

every :tuesday, at: '5 pm' do
  rake 'goodcity:import_swd_organisations'
end

if environment.to_s == "staging"
  every '*/2 * * * *' do
    rake 'goodcity:send_unread_message_reminders'
  end
end