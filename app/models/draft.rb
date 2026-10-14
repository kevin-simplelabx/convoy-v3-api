class Draft < ApplicationRecord
  belongs_to :school

  def self.for_school(school)
    find_or_create_by!(school: school)
  end
end
