# Finance > Vehicle Financials: how an own vehicle was bought (paid in full or a loan) and its instalments paid.
# == Schema Information
#
# Table name: vehicle_financials
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  account_number     :string
#  bought_on          :date
#  down_payment       :decimal(12, 2)
#  first_due_on       :date
#  first_instalment   :decimal(12, 2)
#  funding            :string           default("loan"), not null
#  last_instalment    :decimal(12, 2)
#  lender             :string
#  loan_amount        :decimal(12, 2)
#  monthly_instalment :decimal(12, 2)
#  purchase_price     :decimal(12, 2)
#  rate               :decimal(6, 3)
#  schedule_file      :string
#  tenure_months      :integer
#  term_charge        :decimal(12, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  document_read_id   :bigint
#  updated_by_id      :bigint
#  vehicle_id         :bigint           not null
#
# Indexes
#
#  index_vehicle_financials_on_company_id        (company_id)
#  index_vehicle_financials_on_document_read_id  (document_read_id)
#  index_vehicle_financials_on_updated_by_id     (updated_by_id)
#  index_vehicle_financials_on_vehicle_id        (vehicle_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (document_read_id => document_reads.id)
#  fk_rails_...  (updated_by_id => users.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleFinancial < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits

  mount_uploader :schedule_file, DocumentUploader

  belongs_to :vehicle
  belongs_to :document_read, optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :payments, -> { order(:instalment_no) }, class_name: "VehicleLoanPayment", dependent: :delete_all

  enum :funding, { loan: "loan", cash: "cash" }, prefix: :funded_by, validate: true

  validates :purchase_price, :down_payment, :loan_amount, :term_charge, :first_instalment, :monthly_instalment, :last_instalment,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :tenure_months, numericality: { only_integer: true, in: 1..120 }, allow_nil: true
  validate :loan_terms, if: :funded_by_loan?

  def schedule(today = Date.current) = Finance::LoanSchedule.new(self, today:)

  # no_details | paid_in_full | incomplete | overdue | loan_paid_off | loan_active
  def status(today = Date.current)
    return "paid_in_full" if funded_by_cash?

    s = schedule(today)
    return "incomplete" unless s.valid?
    return "overdue" if s.overdue.any?

    s.next_due.nil? ? "loan_paid_off" : "loan_active"
  end

  private

  def loan_terms
    return if [ loan_amount, tenure_months, first_due_on ].all?(&:blank?)

    errors.add(:loan_amount, "is needed for a loan") if loan_amount.blank?
    errors.add(:tenure_months, "is needed for a loan") if tenure_months.blank?
    errors.add(:first_due_on, "is needed for a loan") if first_due_on.blank?
  end
end
