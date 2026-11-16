# A child in a Household. school_id = a school Convoy runs buses for (School Bus, any company), school_name = its name or the
# name typed when the school is "Other". level = the level next year ("Primary 3", "P3"...). Bus service is applied for
# separately. Delete Family discards it; the records a school or company keeps stay with them.
# == Schema Information
#
# Table name: dependants
# Database name: primary
#
#  id           :bigint           not null, primary key
#  birth_date   :date             not null
#  discarded_at :datetime
#  gender       :string
#  level        :string           not null
#  medical_note :text
#  medical_tags :string           default([]), not null, is an Array
#  name         :string           not null
#  photo        :string
#  school_name  :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  household_id :bigint           not null
#  school_id    :bigint
#  student_id   :string
#
# Indexes
#
#  index_dependants_live_on_household_id  (household_id) WHERE (discarded_at IS NULL)
#  index_dependants_on_household_id       (household_id)
#  index_dependants_on_school_id          (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (household_id => households.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id) ON DELETE => nullify
#
class Dependant < ApplicationRecord
  include Discard::Model

  GENDERS = %w[girl boy].freeze
  MEDICAL_TAGS = [ "Asthma", "Food allergy", "Eczema", "Epilepsy", "Diabetes", "ADHD", "Autism", "Motion sickness", "Heart condition" ].freeze

  audited associated_with: :household, except: %i[photo]

  belongs_to :household, inverse_of: :dependants
  belongs_to :school, optional: true
  has_many :dependant_guardians, dependent: :delete_all

  mount_uploader :photo, ImageUploader

  normalizes :name, :school_name, :level, :student_id, with: ->(v) { v.to_s.squish.presence }
  normalizes :medical_note, with: ->(v) { v.to_s.strip.presence }
  normalizes :gender, with: ->(v) { v.to_s.downcase.presence }

  validates :name, :birth_date, :school_name, :level, presence: true
  validates :name, :school_name, :level, :student_id, length: { maximum: 120 }
  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validate :birth_date_in_past
  validate :medical_tags_known

  def first_name = name.to_s.split.first

  private

  def birth_date_in_past
    errors.add(:birth_date, "must be in the past") if birth_date && birth_date >= Date.current
  end

  def medical_tags_known
    unknown = medical_tags - MEDICAL_TAGS
    errors.add(:medical_tags, "has unknown #{unknown.to_sentence}") if unknown.any?
  end
end
