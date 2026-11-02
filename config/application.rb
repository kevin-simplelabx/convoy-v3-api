require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ConvoyV3
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Default zone for display; each request runs in its company's timezone (Company#timezone).
    config.time_zone = "Singapore"
    config.active_record.default_timezone = :utc
    # structure.sql: trip_occurrences is a partitioned table, which schema.rb cannot describe
    config.active_record.schema_format = :sql

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Re-add session/cookie middleware (needed for Devise cookie sessions).
    # SESSION_SAME_SITE=none lets a FE on another site (e.g. localhost against staging) keep the session.
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: "_convoy_session",
      same_site: ENV.fetch("SESSION_SAME_SITE", "lax").to_sym, secure: Rails.env.production?

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.orm :active_record, primary_key_type: :bigint
    end

    # In-process cache for OSRM proxy responses (survives between requests, resets on restart)
    config.cache_store = :memory_store, { size: 64.megabytes }
  end
end
