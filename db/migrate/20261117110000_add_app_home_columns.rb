# Convoy App › Home, Activity, Alerts (Phase 8), columns on existing tables (indexes concurrently, FKs validated next).
# app_notifications: the child an alert is about, the notice it came from, where a tap opens (target + target_id), how long it
#   shows as a Home banner (banner_until; nil = inbox only) and when the person dismissed the banner. Partial indexes for the
#   unread badge and the Home banners.
# notices.app_sent_at: the notice was copied into the Convoy App inboxes (AppAlertsJob, once, when it is in force).
class AddAppHomeColumns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :app_notifications, :dependant_id, :bigint
    add_column :app_notifications, :notice_id, :bigint
    add_column :app_notifications, :target, :string
    add_column :app_notifications, :target_id, :bigint
    add_column :app_notifications, :banner_until, :datetime
    add_column :app_notifications, :dismissed_at, :datetime
    add_index :app_notifications, :dependant_id, algorithm: :concurrently
    add_index :app_notifications, :notice_id, algorithm: :concurrently
    add_index :app_notifications, :app_account_id, where: "read_at IS NULL", name: "index_app_notifications_unread", algorithm: :concurrently
    add_index :app_notifications, %i[app_account_id banner_until], where: "banner_until IS NOT NULL AND dismissed_at IS NULL",
                                                                   name: "index_app_notifications_banners", algorithm: :concurrently
    add_foreign_key :app_notifications, :dependants, on_delete: :nullify, validate: false
    add_foreign_key :app_notifications, :notices, on_delete: :nullify, validate: false

    add_column :notices, :app_sent_at, :datetime
  end
end
