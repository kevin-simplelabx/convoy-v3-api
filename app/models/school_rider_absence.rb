# == Schema Information
#
# Table name: school_rider_absences
# Database name: primary
#
#  id          :bigint           not null, primary key
#  date        :date             not null
#  note        :string
#  reason      :string           default("other"), not null
#  reported_by :string
#  rid         :string           not null
#  trip        :string           default("both"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  school_id   :bigint           not null
#
# Indexes
#
#  index_school_rider_absences_on_company_id                  (company_id)
#  index_school_rider_absences_on_school_id                   (school_id)
#  index_school_rider_absences_on_school_id_and_date          (school_id,date)
#  index_school_rider_absences_on_school_id_and_rid_and_date  (school_id,rid,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
# A day a child does not need the school bus (Bus Not Required, from the Convoy App): the morning, afternoon or both trips.
class SchoolRiderAbsence < ApplicationRecord
  include TenantScoped

  TRIPS = %w[am pm both].freeze
  REASONS = { "sick" => "Unwell", "leave" => "On leave", "away" => "Away", "own" => "Own transport", "parent" => "Parent picking up",
              "cca" => "CCA", "other" => nil }.freeze

  belongs_to :school

  validates :rid, :date, presence: true
  validates :trip, inclusion: { in: TRIPS }
  validates :reason, inclusion: { in: REASONS.keys }

  # Does it cover a run of this session (am, pm, asa)? A CCA run counts as the afternoon.
  def covers?(session) = trip == "both" || trip == (session == "am" ? "am" : "pm")

  def reason_text = [ REASONS[reason], note.presence ].compact.join(". ").presence
end
