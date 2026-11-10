# A School Bus bill: a family's bill for a billing period (or the school's, when the school pays per rider or per bus;
# billed to its Managed Client), the first invoice of an accepted bus request, or a CCA rides payment. Period bills are
# drafted by Convoy (no number yet) and issued by Finance, which numbers them from Finance Settings (INV-2026-000001)
# with GST. Payments, waivers and the credit / debit notes raised on it decide what is still owed (SchoolBills::Calc).
# == Schema Information
#
# Table name: school_bills
# Database name: primary
#
#  id               :bigint           not null, primary key
#  bill_to          :string
#  bill_to_code     :string
#  bill_to_email    :string
#  billing_month    :date
#  credit_used      :decimal(12, 2)   default(0.0), not null
#  drafted_at       :timestamptz
#  due_at           :timestamptz
#  due_on           :date
#  gross            :decimal(12, 2)
#  gst_amount       :decimal(12, 2)   default(0.0), not null
#  gst_rate         :decimal(5, 2)    default(0.0), not null
#  issued_at        :timestamptz
#  issued_on        :date             not null
#  kind             :string           default("first"), not null
#  number           :string
#  payer            :string           default("family"), not null
#  period_index     :integer
#  period_label     :string
#  period_starts_on :date
#  status           :string           default("draft"), not null
#  subtotal         :decimal(12, 2)   not null
#  total            :decimal(12, 2)   not null
#  week_of          :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint
#  bus_request_id   :bigint
#  client_id        :bigint
#  company_id       :bigint           not null
#  created_by_id    :bigint
#  family_id        :bigint
#  issued_by_id     :bigint
#  school_id        :bigint           not null
#  school_rider_id  :bigint
#
# Indexes
#
#  index_school_bills_on_bus_request_id         (bus_request_id) UNIQUE
#  index_school_bills_on_company_id_and_number  (company_id,number) UNIQUE
#  index_school_bills_on_family_id              (family_id)
#  index_school_bills_on_school_id              (school_id)
#  index_school_bills_one_per_family_period     (school_id,academic_year_id,period_index,family_id) UNIQUE WHERE (((kind)::text = 'period'::text) AND (family_id IS NOT NULL))
#  index_school_bills_one_per_school_period     (school_id,academic_year_id,period_index) UNIQUE WHERE (((kind)::text = 'period'::text) AND ((payer)::text = 'school'::text))
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id)
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => nullify
#  fk_rails_...  (client_id => clients.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => nullify
#  fk_rails_...  (issued_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => nullify
#
class SchoolBill < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  KINDS = %w[first cca period].freeze
  STATUSES = %w[draft issued].freeze
  PAYERS = %w[family school].freeze

  belongs_to :school
  belongs_to :academic_year, optional: true
  belongs_to :family, optional: true
  belongs_to :client, optional: true
  belongs_to :school_rider, optional: true
  belongs_to :bus_request, optional: true, inverse_of: :first_bill
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :issued_by, class_name: "User", optional: true
  has_many :lines, -> { order(:position, :id) }, class_name: "SchoolBillLine", dependent: :delete_all, inverse_of: :school_bill
  has_many :payments, -> { order(:paid_on, :id) }, class_name: "SchoolBillPayment", dependent: :delete_all, inverse_of: :school_bill
  has_many :waivers, -> { order(:id) }, class_name: "SchoolBillWaiver", dependent: :delete_all, inverse_of: :school_bill
  has_many :notes, -> { order(:issued_on, :id) }, class_name: "SchoolDocument", dependent: :destroy, inverse_of: :school_bill

  validates :number, presence: true, uniqueness: { scope: :company_id }, unless: :draft?
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :payer, inclusion: { in: PAYERS }

  scope :issued, -> { where(status: "issued") }
  scope :drafts, -> { where(status: "draft") }

  def draft? = status == "draft"
  def issued? = status == "issued"
  def paid_amount = payments.reject(&:voided?).sum(0.to_d, &:amount)
  # Paid in full (before any late fee); the first invoice turns a request Active once this is true.
  def paid? = issued? && paid_amount >= total - 0.005
  def to_name = bill_to.presence || family&.name || school.name
end
