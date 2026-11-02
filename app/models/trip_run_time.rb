# == Schema Information
#
# Table name: trip_run_times
# Database name: primary
#
#  id           :bigint           not null, primary key
#  time         :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  trip_run_id  :bigint           not null
#  trip_stop_id :bigint           not null
#
# Indexes
#
#  index_trip_run_times_on_company_id                    (company_id)
#  index_trip_run_times_on_trip_run_id                   (trip_run_id)
#  index_trip_run_times_on_trip_run_id_and_trip_stop_id  (trip_run_id,trip_stop_id) UNIQUE
#  index_trip_run_times_on_trip_stop_id                  (trip_stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#  fk_rails_...  (trip_stop_id => trip_stops.id)
#
# The time a run reaches a stop (minutes after midnight); nil when it skips the stop.
class TripRunTime < ApplicationRecord
  include TenantScoped

  belongs_to :run, class_name: "TripRun", foreign_key: :trip_run_id, inverse_of: :times
  belongs_to :trip_stop
end
