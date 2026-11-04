# A decision on a step of a booking's approval: approve or decline (with a note; a decline must say why). carried_from:
# an approval counted from an earlier step (the same person on two steps, "approves both").
# == Schema Information
#
# Table name: booking_approval_acts
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  act                      :string           not null
#  carried_from             :integer
#  note                     :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  booking_approval_id      :bigint           not null
#  booking_approval_step_id :bigint           not null
#  client_user_id           :bigint           not null
#
# Indexes
#
#  idx_on_booking_approval_id_created_at_abfe2828d0         (booking_approval_id,created_at)
#  index_booking_approval_acts_on_booking_approval_step_id  (booking_approval_step_id)
#  index_booking_approval_acts_on_client_user_id            (client_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_approval_id => booking_approvals.id) ON DELETE => cascade
#  fk_rails_...  (booking_approval_step_id => booking_approval_steps.id) ON DELETE => cascade
#  fk_rails_...  (client_user_id => client_users.id)
#
class BookingApprovalAct < ApplicationRecord
  ACTS = %w[approve decline].freeze

  belongs_to :approval, class_name: "BookingApproval", foreign_key: :booking_approval_id, inverse_of: :acts
  belongs_to :step, class_name: "BookingApprovalStep", foreign_key: :booking_approval_step_id, inverse_of: :acts
  belongs_to :client_user

  validates :act, inclusion: { in: ACTS }

  def approve? = act == "approve"
end
