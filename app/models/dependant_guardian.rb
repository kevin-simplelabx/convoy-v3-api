# An adult (other than a Mother or Father, who always can) switched on to receive one child at drop-off.
# == Schema Information
#
# Table name: dependant_guardians
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  dependant_id        :bigint           not null
#  household_member_id :bigint           not null
#
# Indexes
#
#  index_dependant_guardians_on_dependant_id         (dependant_id)
#  index_dependant_guardians_on_household_member_id  (household_member_id)
#  index_dependant_guardians_unique                  (dependant_id,household_member_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (dependant_id => dependants.id) ON DELETE => cascade
#  fk_rails_...  (household_member_id => household_members.id) ON DELETE => cascade
#
class DependantGuardian < ApplicationRecord
  belongs_to :dependant
  belongs_to :household_member
end
