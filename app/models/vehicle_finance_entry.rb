# Vehicle Financials > a revenue or cost entered by hand for a vehicle, once (in the month of its date) or every month
# from its date until repeat_until.
# == Schema Information
#
# Table name: vehicle_finance_entries
# Database name: primary
#
#  id              :bigint           not null, primary key
#  amount          :decimal(12, 2)   not null
#  category        :string           not null
#  entry_on        :date             not null
#  kind            :string           not null
#  note            :text
#  repeat_until    :date
#  repeats_monthly :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  vehicle_id      :bigint           not null
#
# Indexes
#
#  index_vehicle_finance_entries_on_company_id_and_entry_on  (company_id,entry_on)
#  index_vehicle_finance_entries_on_created_by_id            (created_by_id)
#  index_vehicle_finance_entries_on_vehicle_id               (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleFinanceEntry < ApplicationRecord
  include TenantScoped
  audited

  CATEGORIES = { "revenue" => [ "School Bus", "Charter and Trips", "Contract", "Other Revenue" ],
                 "cost" => [ "Road Tax", "Parking and ERP", "Cleaning", "Other Cost" ] }.freeze

  belongs_to :vehicle
  belongs_to :created_by, class_name: "User", optional: true

  enum :kind, { revenue: "revenue", cost: "cost" }, validate: true

  validates :entry_on, presence: { message: "Pick the date" }
  validates :amount, numericality: { greater_than: 0, message: "Enter an amount above zero" }
  validate { errors.add(:category, "is not a #{kind} category") unless CATEGORIES.fetch(kind.to_s, []).include?(category) }

  # Does the entry count in the month (date's first day)?
  def in_month?(month)
    start = entry_on.beginning_of_month
    return start == month unless repeats_monthly

    month >= start && (repeat_until.nil? || month <= repeat_until.beginning_of_month)
  end
end
