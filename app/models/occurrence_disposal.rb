# What happened on a disposal run (the bus and driver at the client's disposal for a block of hours), recorded in the
# Convoy Driver app. The block runs from the agreed time (or from the start, when the coordinator asked to start early;
# a late coordinator does not move it) for the booked hours plus the extensions the client signed for. Over the block,
# overtime is billed in 15-minute blocks rounded down (the first 14 minutes are free); ending early refunds nothing.
# == Schema Information
#
# Table name: occurrence_disposals
# Database name: primary
#
#  id                :bigint           not null, primary key
#  block_starts_at   :datetime         not null
#  booked_minutes    :integer          not null
#  early_start       :boolean          default(FALSE), not null
#  end_odometer      :integer
#  end_photo         :string
#  ended_at          :datetime
#  extension_minutes :integer          default(0), not null
#  km                :integer
#  late_minutes      :integer          default(0), not null
#  occurrence_date   :date             not null
#  overtime_minutes  :integer
#  release_signature :string
#  released_by       :string
#  start_odometer    :integer          not null
#  start_photo       :string
#  started_at        :datetime         not null
#  used_minutes      :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  occurrence_id     :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_fc9484b589  (occurrence_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class OccurrenceDisposal < ApplicationRecord
  include TenantScoped
  audited

  OVERTIME_BLOCK = 15
  # "Block ends in … min · extend if the client needs more"
  NEAR_END_MINUTES = 30

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :disposal
  has_many :runs, -> { order(:started_at, :id) }, class_name: "OccurrenceDisposalRun", dependent: :destroy, inverse_of: :disposal
  has_many :extensions, -> { order(:at, :id) }, class_name: "OccurrenceDisposalExtension", dependent: :destroy, inverse_of: :disposal

  mount_uploader :start_photo, ImageUploader
  mount_uploader :end_photo, ImageUploader
  mount_uploader :release_signature, ImageUploader

  validates :start_odometer, numericality: { only_integer: true, greater_than: 0, less_than: 10_000_000 }
  validates :end_odometer, numericality: { only_integer: true, greater_than_or_equal_to: :start_odometer, less_than: 10_000_000,
                                           message: "must be at least the start reading" }, allow_nil: true
  validates :extension_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def ended? = ended_at.present?

  def booked_total = booked_minutes + extension_minutes

  # The block clock: used, booked, over, overtime billed, standing by (not on a run), and when the block ends.
  def figures(now = Time.current)
    to = ended_at || now
    used = [ ((to - block_starts_at) / 60).floor, 0 ].max
    over = [ used - booked_total, 0 ].max
    on_runs = runs.sum { |r| ((r.ended_at || to) - r.started_at) / 60 }.floor
    { used_minutes: used, booked_minutes: booked_total, over_minutes: over, overtime_minutes: (over / OVERTIME_BLOCK) * OVERTIME_BLOCK,
      standing_by_minutes: [ used - on_runs, 0 ].max, block_ends_at: block_starts_at + booked_total.minutes,
      state: if over.positive? then "over" elsif booked_total - used <= NEAR_END_MINUTES then "near_end" else "within" end }
  end
end
