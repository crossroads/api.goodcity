#! /home/deployer/.rvm/rubies/ruby-2.7.3/bin/ruby

# Executed by CheckMK using a wrapper script in /usr/share/check-mk-agent/local/sidekiq_stats
# #!/bin/sh
# source "/home/deployer/.rvm/scripts/rvm"
# /home/deployer/.rvm/bin/rvm in /opt/rails/goodcity_server/current do bundle exec /opt/rails/goodcity_server/current/script/sidekiq_stats.rb
 
# Load REDIS_URL
require 'dotenv'
Dotenv.load
require 'sidekiq/api'
 
def determine_status(metric, value, warn, crit)
  # 0=ok 1=warn 2=crit 3=unknown
  return 2 if value >= crit
  return 1 if value >= warn
  return 0
end
 
def generate_perf(metric, value, warn, crit)
  # enqueued=5;20;35
  "#{metric}=#{value};#{warn};#{crit}"
end
 
def generate_description(metric, value, warn, crit)
  "#{metric}=#{value}"
end
 
stats = Sidekiq::Stats.new
 
status = 0
service = "Sidekiq"
perf = ""
description = "Sidekiq stats:"
 
metrics = [
  ["enqueued", stats.enqueued, 20, 35],
  ["retries", stats.retry_size, 5, 10],
  ["dead", stats.dead_size, 1, 5],
  ["scheduled", stats.scheduled_size, 10, 20]
]
 
metrics.each do |metric, value, warn, crit|
  status = [status, determine_status(metric, value, warn, crit)].max
  perf << "#{'|' if perf.size > 0}#{generate_perf(metric, value, warn, crit)}"
  description << " #{generate_description(metric, value, warn, crit)}"
end
 
puts "#{status} #{service} #{perf} #{description}"