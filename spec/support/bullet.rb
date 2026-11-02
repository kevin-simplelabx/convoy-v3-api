# Fail a spec when it triggers an N+1 query.
RSpec.configure do |config|
  config.before { Bullet.start_request }
  config.after do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end
