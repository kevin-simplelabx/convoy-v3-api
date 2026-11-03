# A bill to a School Bus family: the first invoice of an accepted bus request (the first billing period at the final
# quote, due when the offer ends) or a CCA rides payment (lines per child, credit used); numbered from Finance Settings
# (INV-2026-000001) with GST when the company charges it. Open until a payment is recorded; School Finance adds the rest.
# == Schema Information
#
# Table name: school_bills
# Database name: primary
#
#  id               :bigint           not null, primary key
#  bill_to          :string
#  credit_used      :decimal(12, 2)   default(0.0), not null
#  due_at           :timestamptz
#  gross            :decimal(12, 2)
#  gst_amount       :decimal(12, 2)   default(0.0), not null
#  gst_rate         :decimal(5, 2)    default(0.0), not null
#  issued_on        :date             not null
#  kind             :string           default("first"), not null
#  method           :string
#  number           :string           not null
#  paid_at          :timestamptz
#  period_label     :string
#  period_starts_on :date
#  status           :string           default("open"), not null
#  subtotal         :decimal(12, 2)   not null
#  total            :decimal(12, 2)   not null
#  week_of          :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint
#  bus_request_id   :bigint
#  company_id       :bigint           not null
#  created_by_id    :bigint
#  family_id        :bigint
#  recorded_by_id   :bigint
#  school_id        :bigint           not null
#  school_rider_id  :bigint
#
# Indexes
#
#  index_school_bills_on_bus_request_id         (bus_request_id) UNIQUE
#  index_school_bills_on_company_id_and_number  (company_id,number) UNIQUE
#  index_school_bills_on_family_id              (family_id)
#  index_school_bills_on_school_id              (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id)
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => nullify
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => nullify
#
class SchoolBill < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  KINDS = %w[first cca].freeze
  STATUSES = %w[open paid void].freeze

  belongs_to :school
  belongs_to :academic_year, optional: true
  belongs_to :family, optional: true
  belongs_to :school_rider, optional: true
  belongs_to :bus_request, optional: true, inverse_of: :first_bill
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :lines, -> { order(:position, :id) }, class_name: "SchoolBillLine", dependent: :delete_all, inverse_of: :school_bill

  validates :number, presence: true, uniqueness: { scope: :company_id }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  def paid? = status == "paid"
end
