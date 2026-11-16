# Alert Settings of one route for one staff rider: on/off, the timings to remind for (rows in shuttle_alert_setting_runs),
# weekdays (0 Sun … 6 Sat, like trips.days), how early (5 / 10 / 15 minutes) and what to hear about. Change alerts (bus / cancelled / no or
# changed service) are written by ConvoyApp::Shuttles::Alerts; reminders, Running Late and Notices are only saved.
# == Schema Information
#
# Table name: shuttle_alert_settings
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  enabled             :boolean          default(TRUE), not null
#  lead_minutes        :integer          default(5), not null
#  notify_bus_change   :boolean          default(TRUE), not null
#  notify_late         :boolean          default(TRUE), not null
#  notify_notices      :boolean          default(TRUE), not null
#  notify_service_days :boolean          default(TRUE), not null
#  weekdays            :integer          default([]), not null, is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  app_account_id      :bigint           not null
#  client_id           :bigint           not null
#  company_id          :bigint           not null
#  trip_id             :bigint           not null
#
# Indexes
#
#  index_shuttle_alert_settings_on_app_account_id              (app_account_id)
#  index_shuttle_alert_settings_on_app_account_id_and_trip_id  (app_account_id,trip_id) UNIQUE
#  index_shuttle_alert_settings_on_client_id                   (client_id)
#  index_shuttle_alert_settings_on_company_id                  (company_id)
#  index_shuttle_alert_settings_on_trip_id                     (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id) ON DELETE => cascade
#
class ShuttleAlertSetting < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  LEADS = [ 5, 10, 15 ].freeze
  DEFAULT_WEEKDAYS = [ 1, 2, 3, 4, 5 ].freeze

  belongs_to :client
  belongs_to :app_account
  belongs_to :trip
  has_many :setting_runs, class_name: "ShuttleAlertSettingRun", dependent: :delete_all, inverse_of: :setting
  has_many :trip_runs, through: :setting_runs

  validates :lead_minutes, inclusion: { in: LEADS }
  validate :weekdays_in_range

  def run_ids = setting_runs.map(&:trip_run_id)

  private

  def weekdays_in_range
    errors.add(:weekdays, "must be days of the week") unless weekdays.all? { (0..6).cover?(it) }
  end
end
