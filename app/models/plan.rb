class Plan < ApplicationRecord
  belongs_to :school

  def self.for_school(school)
    find_or_create_by!(school: school) { |p| p.data = [] }
  end
end
