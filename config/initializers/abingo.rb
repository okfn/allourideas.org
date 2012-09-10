require 'redis-store'
Abingo.cache = ActiveSupport::Cache::RedisStore.new(ENV['REDIS_URL'] || REDIS_CONFIG['hostname'])
