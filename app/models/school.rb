class School < ApplicationRecord
  belongs_to :company
  has_many :datasets, dependent: :destroy
  has_many :riders, dependent: :destroy
  has_one  :plan, dependent: :destroy
  has_one  :draft, dependent: :destroy

  validates :name, presence: true

  DEFAULT_LABELS = {
    "AM"  => { "prefix" => "AM ",  "suffix" => "", "start" => 1, "digits" => 0 },
    "PM"  => { "prefix" => "PM ",  "suffix" => "", "start" => 1, "digits" => 0 },
    "ASA" => { "prefix" => "CCA ", "suffix" => "", "start" => 1, "digits" => 0 }
  }.freeze

  def effective_labels
    DEFAULT_LABELS.merge(labels || {})
  end
end
