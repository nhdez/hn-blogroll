# Cache configuration
Rails.application.configure do
  # Use Redis for caching in production
  if Rails.env.production?
    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  else
    # Use memory store for development
    config.cache_store = :memory_store, { size: 64.megabytes }
  end
end

# Set default cache expiration
Rails.application.config.cache_expires_in = 1.hour