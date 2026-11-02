# == Schema Information
#
# Table name: trip_time_changes
# Database name: primary
#
#  id             :bigint           not null, primary key
#  effective_from :date             not null
#  minutes        :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  created_by_id  :bigint
#  trip_id        :bigint           not null
#  trip_run_id    :bigint
#
# Indexes
#
#  index_trip_time_changes_on_company_id                  (company_id)
#  index_trip_time_changes_on_created_by_id               (created_by_id)
#  index_trip_time_changes_on_trip_id                     (trip_id)
#  index_trip_time_changes_on_trip_id_and_effective_from  (trip_id,effective_from)
#  index_trip_time_changes_on_trip_run_id                 (trip_run_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#
# Every Run From This Date: from effective_from on, the trip (or one shuttle run) runs `minutes` later (or earlier).
class TripTimeChange < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip
  belongs_to :trip_run, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :effective_from, presence: true
  validates :minutes, numericality: { only_integer: true, in: -720..720 }
end
