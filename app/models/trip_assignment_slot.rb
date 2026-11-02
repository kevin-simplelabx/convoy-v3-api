# == Schema Information
#
# Table name: trip_assignment_slots
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  slot_no            :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  trip_assignment_id :bigint           not null
#  trip_run_id        :bigint
#
# Indexes
#
#  index_trip_assignment_slots_on_company_id          (company_id)
#  index_trip_assignment_slots_on_trip_assignment_id  (trip_assignment_id)
#  index_trip_assignment_slots_on_trip_run_id         (trip_run_id)
#  index_trip_assignment_slots_once                   (trip_assignment_id,trip_run_id,slot_no) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_assignment_id => trip_assignments.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
class TripAssignmentSlot < ApplicationRecord
  include TenantScoped

  belongs_to :assignment, class_name: "TripAssignment", foreign_key: :trip_assignment_id, inverse_of: :slots
  belongs_to :trip_run, optional: true

  def key = "#{trip_run&.key || 'trip'}|#{slot_no}"
end
