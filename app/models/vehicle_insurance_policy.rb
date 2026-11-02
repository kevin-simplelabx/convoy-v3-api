# == Schema Information
#
# Table name: vehicle_insurance_policies
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  agent                 :string
#  cover_type            :string
#  current               :boolean          default(TRUE), not null
#  debit_note_date       :date
#  debit_note_number     :string
#  ends_on               :date
#  excess                :decimal(12, 2)
#  excess_third_party    :decimal(12, 2)
#  gst                   :decimal(12, 2)
#  hire_purchase_company :string
#  holder                :string
#  insurer               :string
#  paid_on               :date
#  policy_number         :string
#  premium               :decimal(12, 2)
#  renewed_at            :datetime
#  starts_on             :date
#  total                 :decimal(12, 2)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  vehicle_id            :bigint           not null
#
# Indexes
#
#  index_vehicle_insurance_policies_on_company_id              (company_id)
#  index_vehicle_insurance_policies_on_company_id_and_ends_on  (company_id,ends_on)
#  index_vehicle_insurance_policies_on_vehicle_id              (vehicle_id)
#  index_vehicle_insurance_policies_one_current                (vehicle_id) UNIQUE WHERE current
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# A vehicle's insurance policy with its premium. One is current; Renew Policy moves it to Past Policies.
class VehicleInsurancePolicy < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits

  MAX_DOCUMENTS = 5
  DUE_SOON_DAYS = 30

  belongs_to :vehicle
  has_many :documents, class_name: "VehicleInsuranceDocument", dependent: :destroy, inverse_of: :policy

  validates :excess, :excess_third_party, :premium, :gst, :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, if: -> { starts_on && ends_on }

  scope :current, -> { where(current: true) }
  scope :past, -> { where(current: false).order(ends_on: :desc, renewed_at: :desc) }

  # expired | due_soon (within 30 days) | valid | none (no end date)
  def expiry_status(today = Date.current)
    return "none" unless ends_on
    return "expired" if ends_on < today

    ends_on <= today + DUE_SOON_DAYS ? "due_soon" : "valid"
  end

  # Cover months, for spreading the premium in Vehicle P&L later.
  def cover_months
    return 0 unless starts_on && ends_on

    ((ends_on.year * 12) + ends_on.month) - ((starts_on.year * 12) + starts_on.month) + 1
  end
end
