# Pushes Convoy App inbox alerts (app_notifications) to every phone the account is signed in on, unless the person turned
# Account › Notifications › Push off. The data says what a tap opens, as `target` in the inbox (home.md § Push).
module Push
  class AppAlerts < ApplicationService
    def initialize(ids:)
      @ids = ids
    end

    def call
      alerts = AppNotification.where(id: @ids, pushed_at: nil).joins(:app_account).where(app_accounts: { notify_push: true }).to_a
      devices = AppDevice.where(app_account_id: alerts.map(&:app_account_id).uniq).group_by(&:app_account_id)
      pushed = alerts.select do |alert|
        devices.fetch(alert.app_account_id, []).map { Push.deliver(it, title: alert.title, body: alert.body, data: data(alert)) }.any?
      end
      AppNotification.where(id: pushed.map(&:id)).update_all(pushed_at: Time.current) if pushed.any? # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def data(alert)
      { type: "app_alert", id: alert.id, kind: alert.kind, target: alert.target, target_id: alert.target_id, trip_id: alert.trip_id }
    end
  end
end
