module Goodcity
  class RedisStore
    attr_accessor :params

    def initialize(options = {})
      @params = {
        namespace: ENV['REDIS_NAMESPACE'] || 'goodcity',
        password:  ENV['REDIS_PASSWORD'],
        url:       ENV['REDIS_URL'] || 'redis://localhost:6379'
      }
      @params.merge!(options)
    end

    def init
      Redis.new(@params)
    end
  end
end
