# Files are stored on local disk for now (public/uploads in development, tmp in test).
# Switch to fog/S3 by setting config.storage and fog credentials in production.
CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = !Rails.env.test?
  config.root = Rails.env.test? ? Rails.root.join("tmp/carrierwave") : Rails.root.join("storage")
  config.cache_dir = Rails.root.join("tmp/uploads")
end
