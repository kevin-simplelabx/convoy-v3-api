class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :schools, dependent: :destroy
  has_one  :stop_library, dependent: :destroy
  has_many :vehicles, dependent: :destroy
  has_many :attendants, dependent: :destroy
  has_many :trips, dependent: :destroy

  validates :name, presence: true
  validates :logo, length: { maximum: 400_000 }, allow_nil: true
end
