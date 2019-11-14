# require *_check.rb files in the health_checks folder
Dir.glob(Rails.root.join('lib/goodcity/health_checks/**/*_check.rb')).sort.each {|f| require f }

module Goodcity
  class HealthChecks

    cattr_accessor :checks
    @@checks = []
    
    class << self

      def register_check(check)
        checks << check
      end

      def run_all
        checks.map do |check_klass|
          check = check_klass.new
          check.run
          check.report
        end.compact
      end

      def list_checks
        checks.map do |check|
          "#{check.name} - #{check.desc}"
        end.join("\n")
      end

      # run hook to register health_checks
      ActiveSupport.run_load_hooks(:health_checks, Goodcity::HealthChecks)

    end # class
    
  end
end
