source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Auth
gem "devise"
# JWT Bearer tokens for the API, Allowlist revocation (one row per sign-in) [https://github.com/waiting-for-dev/devise-jwt]
gem "devise-jwt"

# Multi-tenancy (scope every query by company) and authorization
gem "acts_as_tenant"
gem "pundit"

# Presentation: decorators and JSON views
gem "draper"
gem "blueprinter"

# File uploads (every upload goes through CarrierWave)
gem "carrierwave", "~> 3.1"

# Pagination and filtering
gem "pagy", "~> 43.8"
gem "ransack"

# Change history (Changes to This Trip, who changed what)
gem "audited"

# Soft delete (trips, vehicles, drivers stay readable for past occurrences)
gem "discard"

# Safe migrations on large tables (trip_occurrences)
gem "strong_migrations"

# Fast JSON for large responses (Scheduler grid)
gem "oj"

# HTTP client (OSRM proxy, external APIs)
gem "faraday"

# Claude API (reads log cards, insurance papers, invoices, route lists, trip requests)
gem "anthropic"

# Excel / CSV reading (Import Route List)
gem "roo"

# State machines (booking trip: pending, awaiting acknowledgement, approved, rejected...)
gem "aasm"
# Group by day / week / month in the company time zone (Fuel usage, Maintenance spend) [https://github.com/ankane/groupdate]
gem "groupdate"
# Phone numbers: normalise to E.164 and validate (driver invites) [https://github.com/daddyz/phonelib]
gem "phonelib"

# Rate limiting
gem "rack-attack"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Image resizing for CarrierWave versions
gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

group :development do
  gem "dotenv-rails"
  gem "annotaterb"
end

group :development, :test do
  gem "bullet"
end

group :test do
  gem "shoulda-matchers"
end

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end
