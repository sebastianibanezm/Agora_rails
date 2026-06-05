source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "dotenv-rails", groups: %i[development test]
gem "thruster", require: false
gem "image_processing", "~> 2.0"
gem "pdf-reader", "~> 2.14"

# Frontend
gem "vite_rails"
gem "inertia_rails"

# Auth & multi-tenancy
gem "bcrypt", "~> 3.1.7"
gem "acts_as_tenant"
gem "pundit"

# Background jobs
gem "sidekiq"
gem "redis"

# Audit trail
gem "paper_trail"

# Backoffice
gem "avo"

# Monitoring
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
end

group :test do
  gem "minitest-reporters"
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
