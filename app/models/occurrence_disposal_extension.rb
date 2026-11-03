# Extend Time on a disposal (driver-led, no office approval): the block's extra minutes before and after, the client's
# name and signature, and the driver's confirmation that operations was told.
# == Schema Information
#
# Table name: occurrence_disposal_extensions
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  at                     :datetime         not null
#  from_minutes           :integer          not null
#  operations_told        :boolean          default(FALSE), not null
#  signature              :string
#  signed_by              :string           not null
#  to_minutes             :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  occurrence_disposal_id :bigint           not null
#
# Indexes
#
#  index_occurrence_disposal_extensions_on_occurrence_disposal_id  (occurrence_disposal_id)
#
# Foreign Keys
#
#  fk_rails_...  (occurrence_disposal_id => occurrence_disposals.id) ON DELETE => cascade
#
class OccurrenceDisposalExtension < ApplicationRecord
  audited associated_with: :disposal

  belongs_to :disposal, class_name: "OccurrenceDisposal", foreign_key: :occurrence_disposal_id, inverse_of: :extensions

  mount_uploader :signature, ImageUploader

  validates :signed_by, presence: true
end
