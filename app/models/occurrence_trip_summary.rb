# A run's driving summary, worked out from its GPS pings and stop events (Telematics::Summarize).
# == Schema Information
#
# Table name: occurrence_trip_summaries
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  avg_moving_speed_kmh  :decimal(5, 1)
#  distance_km           :decimal(8, 2)
#  ended_at              :datetime
#  fuel_estimated        :boolean          default(TRUE), not null
#  fuel_unit             :string
#  fuel_used             :decimal(8, 2)
#  harsh_events          :integer
#  idle_seconds          :integer
#  max_speed_kmh         :decimal(5, 1)
#  occurrence_date       :date             not null
#  odometer_end_km       :integer
#  odometer_start_km     :integer
#  overspeed_seconds     :integer
#  ping_count            :integer
#  ping_interval_seconds :integer
#  speed_limit_kmh       :integer
#  started_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  occurrence_id         :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_817e8d9e46  (occurrence_id,occurrence_date) UNIQUE
#  index_occurrence_trip_summaries_on_company_id    (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class OccurrenceTripSummary < ApplicationRecord
  include TenantScoped

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :trip_summary

  def duration_minutes = started_at && ended_at ? ((ended_at - started_at) / 60).round : nil
end
