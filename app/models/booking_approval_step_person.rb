# Someone a booking's approval step asked, and why (group, named, fallback = the Admins when no one else was left).
# == Schema Information
#
# Table name: booking_approval_step_people
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  reason                   :string           not null
#  booking_approval_step_id :bigint           not null
#  client_user_id           :bigint           not null
#
# Indexes
#
#  index_booking_approval_step_people_on_client_user_id  (client_user_id)
#  index_booking_approval_step_people_unique             (booking_approval_step_id,client_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (booking_approval_step_id => booking_approval_steps.id) ON DELETE => cascade
#  fk_rails_...  (client_user_id => client_users.id)
#
class BookingApprovalStepPerson < ApplicationRecord
  REASONS = %w[group named fallback].freeze

  belongs_to :booking_approval_step
  belongs_to :client_user

  validates :reason, inclusion: { in: REASONS }
end
