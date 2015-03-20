redis_options = { namespace: 'goodcity' }
redis_options.merge!(namespace: ENV['REDIS_NAMESPACE']) if ENV['REDIS_NAMESPACE'].present?
redis_options.merge!(password: ENV['REDIS_PASSWORD']) if ENV['REDIS_PASSWORD'].present?
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'

if Rails.env.production?
  Rails.application.configure do
    config.cache_store = :redis_store, redis_url, redis_options
  end
end

Sidekiq.redis = redis_options.merge(url: redis_url)

