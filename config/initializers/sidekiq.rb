# Sidekiq Configuration for LMS Payment Processing
# This initializer sets up Sidekiq with Redis

# Set up Redis connection
Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
  }
end

# Configure Sidekiq Web UI if available
if defined?(Sidekiq::Web)
  Sidekiq::Web.configure do |config|
    # Set up authentication for Sidekiq Web UI
    config.app_url = ENV.fetch("APP_URL") { "http://localhost:3000" }

    # Basic authentication (for development)
    if Rails.env.development?
      config.basic_auth = {
        username: ENV.fetch("SIDEKIQ_WEB_USERNAME") { "admin" },
        password: ENV.fetch("SIDEKIQ_WEB_PASSWORD") { "password" }
      }
    end
  end
end

# Set up Sidekiq logger
Sidekiq.logger.level = Logger::INFO if Rails.env.production?
Sidekiq.logger.level = Logger::DEBUG if Rails.env.development?

# Configure error notifications
if Rails.env.production?
  Sidekiq.configure_server do |config|
    config.on(:error) do |ex, ctx|
      # Send error notifications to monitoring service
      Rails.logger.error "Sidekiq error: #{ex.class} - #{ex.message}"
      Rails.logger.error "Context: #{ctx}"

      # You could integrate with services like:
      # - Rollbar
      # - Sentry
      # - Honeybadger
      # - Custom error notification service
    end
  end
end

# Start Sidekiq cron scheduler if available
if defined?(Sidekiq::Cron)
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(
    Rails.root.join("config", "sidekiq.yml")
  ).fetch(:scheduler, {})
end
