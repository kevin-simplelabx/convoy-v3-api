# A Client Portal booking's way through the client's approval flow, as it was when the booking was sent: the matched
# rule (name kept), its steps and the people each step asked, and every decision. status: wait (a step is waiting),
# ok (approved, sent to the transport company), no (declined), none (the flow was on and no step was needed).
# == Schema Information
#
# Table name: booking_approvals
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  current_step            :integer          default(0), not null
#  decided_at              :datetime
#  flow_kind               :string           not null
#  name                    :string           not null
#  same_person             :string           default("once"), not null
#  status                  :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  booking_id              :bigint           not null
#  client_approval_rule_id :bigint
#  company_id              :bigint           not null
#
# Indexes
#
#  index_booking_approvals_on_booking_id               (booking_id) UNIQUE
#  index_booking_approvals_on_client_approval_rule_id  (client_approval_rule_id)
#  index_booking_approvals_on_company_id_and_status    (company_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id) ON DELETE => cascade
#  fk_rails_...  (client_approval_rule_id => client_approval_rules.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#
class BookingApproval < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  STATUSES = %w[wait ok no none].freeze

  belongs_to :booking, inverse_of: :approval
  belongs_to :rule, class_name: "ClientApprovalRule", foreign_key: :client_approval_rule_id, optional: true
  has_many :steps, -> { order(:position) }, class_name: "BookingApprovalStep", inverse_of: :approval, dependent: :destroy
  has_many :acts, -> { order(:created_at, :id) }, class_name: "BookingApprovalAct", inverse_of: :approval, dependent: :delete_all

  validates :status, inclusion: { in: STATUSES }
  validates :same_person, inclusion: { in: ClientApprovalRule::SAME_PERSON }

  def waiting? = status == "wait"
  def step_at(position) = steps.find { it.position == position }
  def current = step_at(current_step)
end
