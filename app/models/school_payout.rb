# One operator's pay run for a school's month (School Finance › Operator Payments): open while the month runs (route pay
# worked out live), sent to Finance by Ops (route pay, routes and the replacement lines kept), sent back or approved by
# an approver (another person when maker-checker is on), then paid here (Payment Voucher) or in an Operator Payments batch.
# == Schema Information
#
# Table name: school_payouts
# Database name: primary
#
#  id             :bigint           not null, primary key
#  approved_at    :timestamptz
#  auto_lines     :jsonb            not null
#  base           :decimal(12, 2)
#  invoice_number :string
#  month          :date             not null
#  returned_at    :timestamptz
#  routes_count   :integer
#  sent_at        :timestamptz
#  status         :string           default("draft"), not null
#  voucher_number :string
#  voucher_on     :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  approved_by_id :bigint
#  company_id     :bigint           not null
#  operator_id    :bigint           not null
#  prepared_by_id :bigint
#  returned_by_id :bigint
#  school_id      :bigint           not null
#  sent_by_id     :bigint
#
# Indexes
#
#  index_school_payouts_on_company_id_and_status                (company_id,status)
#  index_school_payouts_on_operator_id                          (operator_id)
#  index_school_payouts_on_school_id_and_month_and_operator_id  (school_id,month,operator_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (operator_id => operators.id)
#  fk_rails_...  (prepared_by_id => users.id)
#  fk_rails_...  (returned_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (sent_by_id => users.id)
#
class SchoolPayout < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  STATUSES = %w[draft ready approved].freeze

  belongs_to :school
  belongs_to :operator
  belongs_to :prepared_by, class_name: "User", optional: true
  belongs_to :sent_by, class_name: "User", optional: true
  belongs_to :returned_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :adjustments, -> { order(:adj_on, :id) }, class_name: "SchoolPayoutAdjustment", dependent: :destroy, inverse_of: :school_payout
  has_many :payments, -> { order(:paid_on, :id) }, class_name: "SchoolPayoutPayment", dependent: :delete_all, inverse_of: :school_payout

  validates :status, inclusion: { in: STATUSES }

  def draft? = status == "draft"
  def paid_amount = payments.sum(0.to_d, &:amount)
  # Kept from the moment it went to Finance: route pay, replacement lines.
  def locked? = !draft? || payments.any?
end
