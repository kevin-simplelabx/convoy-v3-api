class Dataset < ApplicationRecord
  belongs_to :school

  validates :effective_from, presence: true
  validates :rows, presence: true

  scope :active_on, ->(date) { where("effective_from <= ?", date).order(effective_from: :desc) }
end
