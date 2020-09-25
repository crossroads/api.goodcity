module Goodcity
  module Authentication
    module Strategies
      class BaseStrategy
        attr_accessor :user

        def initialize(params = {})
          @params = params
          @user   = nil
        end

        def request_params
          @params
        end

        def valid?
          true
        end

        def authenticate
          return nil unless valid?
          @user ||= begin 
            execute
          rescue
            nil
          end
        end

        def authenticated?
          @user.present?
        end

        def execute
          raise NotImplementedError
        end
      end
    end
  end
end