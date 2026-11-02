# == Schema Information
#
# Table name: student_attendances
# Database name: primary
#
#  id             :bigint           not null, primary key
#  absent         :boolean          default(FALSE), not null
#  alighted_at    :datetime
#  boarded_at     :datetime
#  run_date       :date             not null
#  slot_no        :integer          default(1), not null
#  student_key    :uuid             not null
#  student_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  recorded_by_id :bigint
#  trip_id        :bigint           not null
#  trip_run_id    :bigint
#
# Indexes
#
#  index_student_attendances_on_company_id      (company_id)
#  index_student_attendances_on_recorded_by_id  (recorded_by_id)
#  index_student_attendances_on_trip_id         (trip_id)
#  index_student_attendances_on_trip_run_id     (trip_run_id)
#  index_student_attendances_once               (trip_id,run_date,trip_run_id,slot_no,student_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
# Passenger List: a student's boarding on one run (Boarded, Alighted, Absent). Kept to protect our drivers; never sent
# to a school system. The run is named by its identity (trip, date, run, slot).
class StudentAttendance < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :trip
  belongs_to :trip_run, optional: true
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :student_key, :student_name, presence: true

  def status
    return "absent" if absent?
    return "alighted" if alighted_at
    return "boarded" if boarded_at

    "not_marked"
  end
end
