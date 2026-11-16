# A timing ticked in an Alert Setting.
# == Schema Information
#
# Table name: shuttle_alert_setting_runs
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  shuttle_alert_setting_id :bigint           not null
#  trip_run_id              :bigint           not null
#
# Indexes
#
#  index_shuttle_alert_setting_runs_on_trip_run_id  (trip_run_id)
#  index_shuttle_alert_setting_runs_unique          (shuttle_alert_setting_id,trip_run_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shuttle_alert_setting_id => shuttle_alert_settings.id) ON DELETE => cascade
#  fk_rails_...  (trip_run_id => trip_runs.id) ON DELETE => cascade
#
class ShuttleAlertSettingRun < ApplicationRecord
  belongs_to :setting, class_name: "ShuttleAlertSetting", foreign_key: :shuttle_alert_setting_id, inverse_of: :setting_runs
  belongs_to :trip_run
end
