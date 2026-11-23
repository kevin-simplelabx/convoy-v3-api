# Push notifications to the Driver app and the Convoy App, through Firebase Cloud Messaging (Android and iOS; the APNs key
# lives in the Firebase project, not here). A push is a copy of a bell / inbox line that is already saved: the writers
# queue PushJob after commit, the job sends to the phones of the account and sets `pushed_at` when one got it.
#   Push::DriverNotifications  driver_notifications → the driver_devices of the driver account (every company)
#   Push::AppAlerts            app_notifications    → the app_devices of the app account (Notifications › Push on)
# The client is Push::Fcm when FIREBASE_CREDENTIALS (the service account JSON, raw or Base64) is set, else Push::Off
# (nothing sent); specs use FakePush. `Push.pausing { }` queues nothing (the seed).
module Push
  Error = Class.new(StandardError)

  thread_mattr_accessor :paused

  class << self
    attr_writer :client

    def client = @client ||= (json = credentials) ? Fcm.new(json) : Off.new

    def credentials
      value = ENV["FIREBASE_CREDENTIALS"].to_s.strip
      return if value.empty?

      value.start_with?("{") ? value : Base64.strict_decode64(value)
    end

    def pausing(&)
      was = paused
      self.paused = true
      yield
    ensure
      self.paused = was
    end

    # Queues the push of these saved lines once the surrounding transaction commits.
    def later(source, ids)
      ids = Array(ids).compact.uniq
      return if ids.empty? || paused

      ActiveRecord.after_all_transactions_commit { PushJob.perform_later(source, ids) }
    end

    # Sends one message to a device; true when the phone got it. A token Firebase no longer knows is forgotten; other
    # failures are reported (the line stays in the bell / inbox).
    def deliver(device, title:, body:, data:)
      case client.deliver(token: device.push_token, title:, body:, data: data.compact.transform_values(&:to_s))
      when :sent then true
      when :unregistered then device.delete && false
      else false
      end
    rescue Error => e
      raise if Rails.env.test?

      Rails.error.report(e, handled: true, context: { push: device.class.name, device_id: device.id })
      false
    end
  end
end
