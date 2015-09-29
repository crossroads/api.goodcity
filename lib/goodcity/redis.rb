require 'redis'

module Goodcity
  class Redis < ::Redis
    def initialize(options = {})
      opts = {
        namespace: ENV['REDIS_NAMESPACE'] || 'goodcity',
        password:  ENV['REDIS_PASSWORD'],
        url:       ENV['REDIS_URL'] || 'redis://localhost:6379'
      }
      super(opts.merge(options))
    end
  end
end
