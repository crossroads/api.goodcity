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

      # This method registers the check subclass whereever the Base module is subclassed
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
        "#{status} #{name}" << (!message.blank? ? " - #{message}" : "")
      end
    end
  end
end
