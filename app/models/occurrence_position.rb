# A GPS ping of a run (partitioned by month on the run's date). Written in bulk by Telematics::Record.
# == Schema Information
#
# Table name: occurrence_positions
# Database name: primary
#
#  id              :bigint           not null, primary key
#  heading         :integer
#  lat             :float            not null
#  lng             :float            not null
#  occurrence_date :date             not null
#  recorded_at     :timestamptz      not null
#  speed_kmh       :float(24)
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#
# Indexes
#
#  index_occurrence_positions_on_recorded_at  (recorded_at) USING brin
#  index_occurrence_positions_on_run          (occurrence_id,occurrence_date,recorded_at)
#
# Foreign Keys
#
#  occurrence_positions_company_id_fkey  (company_id => companies.id)
#
class OccurrencePosition < ApplicationRecord
  include TenantScoped

  self.primary_key = :id

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date]
end
