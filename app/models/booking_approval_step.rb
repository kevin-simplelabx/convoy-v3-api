# A step of a booking's approval: who it asks (groups, the label as shown), any one or everyone, and the people it
# asked when the booking was sent (each with why: the group, named, or the Admins as fallback).
# == Schema Information
#
# Table name: booking_approval_steps
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  fallback            :boolean          default(FALSE), not null
#  label               :string           not null
#  need                :string           default("any"), not null
#  position            :integer          not null
#  who                 :string           default([]), not null, is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  booking_approval_id :bigint           not null
#
# Indexes
#
#  idx_on_booking_approval_id_position_0452e598f2  (booking_approval_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (booking_approval_id => booking_approvals.id) ON DELETE => cascade
#
class BookingApprovalStep < ApplicationRecord
  belongs_to :approval, class_name: "BookingApproval", foreign_key: :booking_approval_id, inverse_of: :steps
  has_many :step_people, class_name: "BookingApprovalStepPerson", dependent: :delete_all
  has_many :people, through: :step_people, source: :client_user
  has_many :acts, class_name: "BookingApprovalAct", inverse_of: :step, dependent: :delete_all
end
