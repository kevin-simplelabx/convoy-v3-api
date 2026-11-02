# == Schema Information
#
# Table name: trip_run_slots
# Database name: primary
#
#  id                :bigint           not null, primary key
#  slot_no           :integer          not null
#  unassigned        :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  trip_run_group_id :bigint
#  trip_run_id       :bigint           not null
#  vehicle_id        :bigint
#
# Indexes
#
#  index_trip_run_slots_on_company_id               (company_id)
#  index_trip_run_slots_on_trip_run_group_id        (trip_run_group_id)
#  index_trip_run_slots_on_trip_run_id              (trip_run_id)
#  index_trip_run_slots_on_trip_run_id_and_slot_no  (trip_run_id,slot_no) UNIQUE
#  index_trip_run_slots_on_vehicle_id               (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_run_group_id => trip_run_groups.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# Vehicle for Each Run: the bus of vehicle slot n on one run. unassigned = sent to Unassigned Trips on purpose.
# group_key (write) names a Runs That Move Together group in the form ("g1"); Trips::Timetable turns keys into groups.
class TripRunSlot < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :run, class_name: "TripRun", foreign_key: :trip_run_id, inverse_of: :slots
  belongs_to :vehicle, optional: true
  belongs_to :trip_run_group, optional: true

  attr_accessor :group_key

  before_validation { self.vehicle = nil if unassigned? }

  validates :slot_no, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :trip_run_id }

  def trip = run.trip

  # "d1r0|1": the run and slot, as the front end and assignments name it.
  def key = "#{run.key}|#{slot_no}"
end
