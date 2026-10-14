class Vehicle < ApplicationRecord
  belongs_to :company
  validates :plate, presence: true
  before_validation { self.plate = plate.to_s.strip.upcase }
end
