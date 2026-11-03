# A file with a pay run line (a receipt, a photo of the damage, a taxi claim), kept private and downloaded by signed link.
# == Schema Information
#
# Table name: school_payout_files
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  file                        :string           not null
#  name                        :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  school_payout_adjustment_id :bigint           not null
#
# Indexes
#
#  index_school_payout_files_on_school_payout_adjustment_id  (school_payout_adjustment_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_payout_adjustment_id => school_payout_adjustments.id) ON DELETE => cascade
#
class SchoolPayoutFile < ApplicationRecord
  belongs_to :school_payout_adjustment, inverse_of: :files

  mount_uploader :file, DocumentUploader
end
