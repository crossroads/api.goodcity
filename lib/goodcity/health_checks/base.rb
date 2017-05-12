module Goodcity
  class HealthChecks

    class Base
      PASSED = "PASSED"
      FAILED = "FAILED"
      PENDING = "PENDING"
      attr :status, :message

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

      def self.desc(msg)
        @desc = msg
      end

      def desc
        self.class.instance_variable_get("@desc")
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
    end

  end
end