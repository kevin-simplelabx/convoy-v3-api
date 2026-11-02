# == Schema Information
#
# Table name: calendars
# Database name: primary
#
#  id                :bigint           not null, primary key
#  afternoon_time    :integer          default(810), not null
#  discarded_at      :datetime
#  kind              :string           not null
#  morning_time      :integer          default(450), not null
#  name              :string           not null
#  observed_holidays :string           default("off"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#
# Indexes
#
#  index_calendars_on_company_id           (company_id)
#  index_calendars_on_company_id_and_name  (company_id,name) UNIQUE WHERE (discarded_at IS NULL)
#  index_calendars_on_discarded_at         (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A calendar a recurring trip can follow: school (holidays, no school, early dismissal, late arrival)
# or general (days off, changed times, off in lieu, working holidays).
class Calendar < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits
  include Discard::Model
  include MinuteTime

  MOE_PRESET = YAML.load_file(Rails.root.join("config/presets/moe_school_holidays.yml"))["moe"].freeze

  has_many :days, -> { order(:starts_on) }, class_name: "CalendarDay", dependent: :destroy, inverse_of: :calendar

  enum :kind, { school: "school", general: "general" }, validate: true
  enum :observed_holidays, { off: "off", work: "work" }, prefix: :observed, validate: true

  accepts_nested_attributes_for :days, allow_destroy: true
  minute_time :morning_time, :afternoon_time

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false, conditions: -> { kept },
                                                 message: "is already used by another calendar" }
  validate { errors.add(:name, "is the built-in calendar's name") if name.to_s.casecmp?("Public Holidays") }
  validate(on: :update) { errors.add(:kind, "can't be changed") if kind_changed? }

  def self.ransackable_attributes(_auth = nil) = %w[name kind]

  include SyncsOccurrences

  has_many :trips, dependent: :restrict_with_error

  after_update_commit if: -> { saved_change_to_observed_holidays? || saved_change_to_morning_time? || saved_change_to_afternoon_time? } do
    resync_occurrences(trips.kept)
  end

  # A calendar in use by a trip can't be deleted.
  def in_use? = trips.kept.exists?

  # Fill a school calendar with the MOE holidays.
  def apply_moe_preset!
    MOE_PRESET.each do |d|
      days.find_or_create_by!(kind: :hol, starts_on: d["from"], ends_on: d["to"]) { |day| day.label = d["label"] }
    end
  end
end
