# One stop of a corrected run, by its place in travel order (nil = as recorded).
# == Schema Information
#
# Table name: occurrence_correction_stops
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  alighted                 :integer
#  arrived_at               :integer
#  boarded                  :integer
#  departed_at              :integer
#  position                 :integer          not null
#  stop_name                :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  company_id               :bigint           not null
#  occurrence_correction_id :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_correction_id_position_806b25c265  (occurrence_correction_id,position) UNIQUE
#  index_occurrence_correction_stops_on_company_id      (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (occurrence_correction_id => occurrence_corrections.id)
#
class OccurrenceCorrectionStop < ApplicationRecord
  include TenantScoped
  include MinuteTime

  FIELDS = %i[arrived_at departed_at boarded alighted].freeze

  audited associated_with: :correction
  minute_time :arrived_at, :departed_at

  belongs_to :correction, class_name: "OccurrenceCorrection", foreign_key: :occurrence_correction_id, inverse_of: :stops

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :boarded, :alighted, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
