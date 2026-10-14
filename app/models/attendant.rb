class Attendant < ApplicationRecord
  belongs_to :company
  validates :name, presence: true
  before_validation { self.name = name.to_s.strip }
end
