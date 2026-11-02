# == Schema Information
#
# Table name: operators
# Database name: primary
#
#  id             :bigint           not null, primary key
#  account_name   :string
#  account_number :string
#  bank_code      :string
#  branch_code    :string
#  contact_name   :string
#  cost_per_day   :decimal(12, 2)
#  cost_per_trip  :decimal(12, 2)
#  discarded_at   :datetime
#  email          :string
#  kind           :string           default("managed"), not null
#  name           :string           not null
#  payment_method :string
#  paynow_uen     :string
#  phone          :string
#  uen            :string
#  valid_until    :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  bank_id        :bigint
#  company_id     :bigint           not null
#
# Indexes
#
#  index_operators_on_bank_id                       (bank_id)
#  index_operators_on_company_id                    (company_id)
#  index_operators_on_company_id_and_kind_and_name  (company_id,kind,name) UNIQUE WHERE (discarded_at IS NULL)
#  index_operators_on_discarded_at                  (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (bank_id => banks.id)
#  fk_rails_...  (company_id => companies.id)
#
# A transport operator whose buses we use: managed (kept on file) or external (one-off or short hire).
# Managed operators are paid by PayNow (to their UEN) or bank transfer, payment_method being the default; the branch
# code is worked out from the account number (Banks::BranchFor) unless the bank's branch is picked from a list.
class Operator < ApplicationRecord
  include TenantScoped
  audited
  include Discard::Model

  UEN = Uen::FORMAT
  UEN_HINT = Uen::HINT

  has_many :vehicles, dependent: :restrict_with_error
  has_many :drivers, class_name: "OperatorDriver", dependent: :restrict_with_error
  belongs_to :bank, optional: true

  enum :kind, { managed: "managed", external: "external" }, validate: true
  enum :payment_method, { paynow: "paynow", bank: "bank" }, validate: { allow_nil: true }

  normalizes :name, with: ->(v) { v.to_s.squish }
  normalizes :uen, :paynow_uen, with: ->(v) { v.to_s.strip.upcase.presence }
  normalizes :account_number, with: ->(v) { v.to_s.gsub(/\D/, "").presence }

  validates :name, presence: true, uniqueness: { scope: %i[company_id kind], case_sensitive: false, conditions: -> { kept } }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :uen, format: { with: UEN, message: "looks wrong. #{UEN_HINT}" }, allow_nil: true
  validates :cost_per_trip, :cost_per_day, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :payment_details, if: :managed?

  before_validation :fill_bank_codes

  def self.ransackable_attributes(_auth = nil) = %w[name kind uen]

  # External company matched by name (case-insensitive), created when new. Used by the New External Vehicle form.
  def self.external_named(name)
    external.kept.where("LOWER(name) = ?", name.to_s.squish.downcase).first || external.new(name:)
  end

  def valid_on?(date) = valid_until.nil? || valid_until >= date

  # Account number as sent in payment files (some banks drop the branch digits).
  def account_number_sent = bank && account_number && Banks::BranchFor.call(bank:, account_number:, branch_code:)[:send]

  def bank_details? = bank_id.present? || account_number.present? || account_name.present?

  private

  # PayNow defaults to the UEN; bank details, when given, must be complete with a branch code.
  def fill_bank_codes
    self.paynow_uen ||= uen if managed? && payment_method != "bank"
    self.bank_code = bank&.code
    self.branch_code = nil if bank_id_changed? && !branch_code_changed?
    @branch_error = nil
    return unless bank && account_number

    branch = Banks::BranchFor.call(bank:, account_number:, branch_code:)
    branch[:code] ? self.branch_code = branch[:code] : @branch_error = branch
  end

  def payment_details
    errors.add(:paynow_uen, "is needed, or pick Bank Transfer") if payment_method != "bank" && paynow_uen.blank?
    errors.add(:paynow_uen, "looks wrong. #{UEN_HINT}") if paynow_uen.present? && !paynow_uen.match?(UEN)
    return unless payment_method == "bank" || bank_details?

    errors.add(:bank, "must be picked") unless bank
    errors.add(:account_number, "should be 6 to 14 digits") unless account_number.to_s.length.between?(6, 14)
    errors.add(:account_name, "is needed, as shown on the bank account") if account_name.blank?
    errors.add(@branch_error[:field], @branch_error[:error_message]) if @branch_error
  end
end
