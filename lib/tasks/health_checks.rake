require 'goodcity/health_checks'

task health_checks: :environment do
  health_checks = Goodcity::HealthChecks.new
  puts health_checks.run
end

namespace :health_checks do
  task :list do
    health_checks = Goodcity::HealthChecks.new
    puts health_checks.list_checks
  end
end