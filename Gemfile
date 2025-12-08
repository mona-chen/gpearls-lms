source "https://rubygems.org"

ruby "~> 3.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0"
# Use sqlite3 for development and test, postgresql for production
gem "sqlite3", "~> 1.4", group: [ :development, :test ]
gem "pg", "~> 1.1", group: :production
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Authentication & Authorization
gem "devise", "~> 4.9"
gem "devise-jwt", "~> 0.10"
gem "cancancan", "~> 3.5"

# File Storage & Processing
gem "aws-sdk-s3", "~> 1.120"
gem "image_processing", "~> 1.2"

# Background Processing & Caching
gem "redis", ">= 4.0.1"

# Pagination & Search
gem "kaminari", "~> 1.2"
gem "ransack", "~> 4.0"

# Ordering & Organization
gem "acts_as_list", "~> 1.0"
gem "friendly_id", "~> 5.5"

# Activity Tracking
gem "public_activity", "~> 2.0"

# Background Processing
gem "sidekiq", "~> 7.0"
gem "sidekiq-status", "~> 1.0"

# Payment Processing
gem "paystack", "~> 0.1"
gem "stripe", "~> 8.0"
gem "razorpay", "~> 2.0"

# CORS support
gem "rack-cors"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Zoom API integration (commented out for testing)
# gem 'zoomrb'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing Framework
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.0"
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.1"
  gem "webmock", "~> 3.18"
end

group :test do
  gem "database_cleaner-active_record", "~> 2.1"
end

gem "rubyzip", "~> 3.2"

gem "nokogiri", "~> 1.18"
