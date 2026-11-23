# Pushes Driver app bell lines (driver_notifications) to the phone of the driver account, whichever company the line is
# from. The data says what a tap opens: the app picks `membership` (PATCH /driver/session) when it is not the current one,
# refetches the bell and opens the line as the bell does (notifications.md § Push).
module Push
  class DriverNotifications < ApplicationService
    def initialize(ids:)
      @ids = ids
    end

    def call
      ActsAsTenant.without_tenant do
        lines = DriverNotification.where(id: @ids, pushed_at: nil).to_a
        accounts = Realtime.driver_accounts(lines.map { { driver_id: it.driver_id, operator_driver_id: it.operator_driver_id } })
        devices = DriverDevice.where(driver_account_id: accounts.values.uniq).group_by(&:driver_account_id)
        pushed = lines.select do |line|
          member = line.driver_id ? [ :driver, line.driver_id ] : [ :operator_driver, line.operator_driver_id ]
          devices.fetch(accounts[member], []).map { Push.deliver(it, title: line.title, body: line.body, data: data(line, member)) }.any?
        end
        DriverNotification.where(id: pushed.map(&:id)).update_all(pushed_at: Time.current) if pushed.any? # rubocop:disable Rails/SkipsModelValidations
      end
    end

    private

    def data(line, member)
      { type: "driver_notification", id: line.id, kind: line.kind, company_id: line.company_id, membership: "#{member[0]}-#{member[1]}",
        run_id: line.occurrence_id, run_date: line.occurrence_date&.iso8601, notice_id: line.driver_notice_id, vehicle_id: line.vehicle_id }
    end
  end
end
