# A school a user can open (Settings > Users > Schools) when the user is not on All Schools.
# == Schema Information
#
# Table name: user_schools
# Database name: primary
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  school_id  :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_schools_on_school_id              (school_id)
#  index_user_schools_on_user_id_and_school_id  (user_id,school_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id)
#
class UserSchool < ApplicationRecord
  audited associated_with: :user

  belongs_to :user
  belongs_to :school

  validates :school_id, uniqueness: { scope: :user_id }
end
