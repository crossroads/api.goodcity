#
#  class TestSomethingCheck
#    include Goodcity::HealthChecks::Base
#  end
#

require 'active_support'
require 'goodcity/health_checks'

module Goodcity
  class HealthChecks
    class Base
    
      PASSED = "PASSED"
      FAILED = "FAILED"
      PENDING = "PENDING"
      attr :status, :message

      # This method registers the check subclass wherever the Base module is subclassed
      def self.inherited(subclass)
        ActiveSupport.on_load(:health_checks) do
          Goodcity::HealthChecks.register_check(subclass)
        end
      end

      class << self
        attr_accessor :desc
      end

      def initialize
        @status = PENDING
        @message = ""
      end

      def run
        raise NotImplementedError
      end

      def name
        self.class.name.demodulize
      end

      def self.desc(msg=nil)
        @desc ||= msg
      end

      def pass!
        @status = PASSED
      end

      def fail!
        @status = FAILED
      end

      def fail_with_message!(msg)
        fail!
        @message = msg
      end

      def passed?
        @status == PASSED
      end

      def failed?
        @status == FAILED
      end

      def report
        if failed?
          "#{status} #{name}" << (!message.blank? ? " - #{message}" : "")
        end
      end

      def write_log_file(ids)
        file_name = self.class.name
        file_path = File.join(Rails.application.root, "tmp", file_name, Rails.application.env)
        CSV.open(file_path, "wb") do |csv|
          csv << headers
          contents.each do |row|
            csv << row
          end
        end
      end

    end
  end
end
