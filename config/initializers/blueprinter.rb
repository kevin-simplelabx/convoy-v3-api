Blueprinter.configure do |config|
  config.generator = Oj
  # Drop nil fields only where a blueprint asks for it; keep explicit nulls by default.
  config.datetime_format = ->(datetime) { datetime&.iso8601 }
end
