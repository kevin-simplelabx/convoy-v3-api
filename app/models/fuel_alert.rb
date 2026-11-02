# One unusual fill (or a bus's rising use per km) for Needs a Look, found by FuelAlerts::Scan. Open until someone
# presses Mark Checked; Undo moves it back.
# == Schema Information
#
# Table name: fuel_alerts
# Database name: primary
#
#  id            :bigint           not null, primary key
#  checked_at    :datetime
#  date          :date             not null
#  key           :string           not null
#  kind          :string           not null
#  message       :text             not null
#  metric        :string
#  status        :string           default("open"), not null
#  tone          :string           default("warn"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  checked_by_id :bigint
#  company_id    :bigint           not null
#  fuel_entry_id :bigint
#  vehicle_id    :bigint           not null
#
# Indexes
#
#  index_fuel_alerts_on_checked_by_id                   (checked_by_id)
#  index_fuel_alerts_on_company_id_and_key              (company_id,key) UNIQUE
#  index_fuel_alerts_on_company_id_and_status_and_date  (company_id,status,date)
#  index_fuel_alerts_on_fuel_entry_id                   (fuel_entry_id)
#  index_fuel_alerts_on_vehicle_id                      (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (checked_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (fuel_entry_id => fuel_entries.id) ON DELETE => cascade
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class FuelAlert < ApplicationRecord
  include TenantScoped
  audited

  KINDS = %w[eff odo dbl big price trend].freeze

  belongs_to :vehicle
  belongs_to :fuel_entry, optional: true
  belongs_to :checked_by, class_name: "User", optional: true

  enum :status, { open: "open", checked: "checked" }, validate: true

  validates :kind, inclusion: { in: KINDS }
  validates :key, :message, :date, presence: true

  def check!(user) = update!(status: :checked, checked_by: user, checked_at: Time.current)
  def reopen! = update!(status: :open, checked_by: nil, checked_at: nil)
end
