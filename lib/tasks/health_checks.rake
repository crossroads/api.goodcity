require 'goodcity/health_checks'

namespace :health_checks do

  desc "List all health checks"
  task :list do
    puts Goodcity::HealthChecks.list_checks
  end

  desc "Health checks"
  task run_all: :environment do
    puts Goodcity::HealthChecks.run_all
  end

  # create a run task for each registered health check
  Goodcity::HealthChecks.checks.each do |check|
    desc check.desc
    task check.name.split("::").last.underscore => :environment do
      c = check.new
      c.run
      puts c.report
    end
  end

end
