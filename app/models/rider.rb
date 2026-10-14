class Rider < ApplicationRecord
  belongs_to :school

  validates :name, presence: true

  def active_on?(date)
    (start_date.nil? || start_date <= date) &&
      (end_date.nil? || end_date >= date)
  end
end
