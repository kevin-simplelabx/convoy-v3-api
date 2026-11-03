# One run on a disposal, as the coordinator directed it: tapped on and off in the Driver app, with the road at each end
# (from the phone's reverse geocoding) and the passengers when the trip counts them.
# == Schema Information
#
# Table name: occurrence_disposal_runs
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  ended_at               :datetime
#  from_lat               :float
#  from_lng               :float
#  from_road              :string
#  pax                    :integer
#  started_at             :datetime         not null
#  to_lat                 :float
#  to_lng                 :float
#  to_road                :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  occurrence_disposal_id :bigint           not null
#
# Indexes
#
#  index_occurrence_disposal_runs_on_occurrence_disposal_id  (occurrence_disposal_id)
#
# Foreign Keys
#
#  fk_rails_...  (occurrence_disposal_id => occurrence_disposals.id) ON DELETE => cascade
#
class OccurrenceDisposalRun < ApplicationRecord
  audited associated_with: :disposal

  belongs_to :disposal, class_name: "OccurrenceDisposal", foreign_key: :occurrence_disposal_id, inverse_of: :runs

  validates :pax, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def open? = ended_at.nil?
end
