# Model and service specs run inside a company unless they say otherwise.
RSpec.configure do |config|
  config.after { ActsAsTenant.current_tenant = nil }
end
