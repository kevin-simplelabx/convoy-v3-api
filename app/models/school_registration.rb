# School Bus › Bus Service Registration of a school's academic year: renewals window (renew_from..renew_to), then
# everyone (general_from..general_to), service start, hours to confirm a seat, mid-year reply times, the levels and
# sessions parents can apply for, the graduating thank-you, auto-accept rules, fees shown, form questions and the
# 12 parent messages. Draft until scheduled; a scheduled registration opens to parents on renew_from.
# == Schema Information
#
# Table name: school_registrations
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  ack_days            :integer          default(3), not null
#  asks                :string           default(["cls", "med", "emerg", "cca"]), not null, is an Array
#  auto_near           :boolean          default(FALSE), not null
#  auto_renew          :boolean          default(TRUE), not null
#  auto_siblings       :boolean          default(FALSE), not null
#  confirm_hours       :integer          default(48), not null
#  extra_terms         :text
#  general_from        :date             not null
#  general_to          :date             not null
#  grad_link           :boolean          default(TRUE), not null
#  grad_message        :text
#  grad_on             :boolean          default(TRUE), not null
#  levels              :string           default([]), not null, is an Array
#  near_km             :decimal(5, 2)    default(3.0), not null
#  near_needs_cover    :boolean          default(TRUE), not null
#  plan_weeks          :integer          default(3), not null
#  renew_check_address :boolean          default(TRUE), not null
#  renew_check_debt    :boolean          default(TRUE), not null
#  renew_check_session :boolean          default(TRUE), not null
#  renew_from          :date             not null
#  renew_to            :date             not null
#  run_at              :integer          default(540), not null
#  run_mode            :string           default("arrive"), not null
#  seats_buffer        :integer          default(3), not null
#  service_starts_on   :date             not null
#  sessions            :string           default(["AM", "PM", "CCA"]), not null, is an Array
#  show_fare           :boolean          default(TRUE), not null
#  siblings_need_cover :boolean          default(TRUE), not null
#  status              :string           default("draft"), not null
#  waitlist_auto       :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  academic_year_id    :bigint           not null
#  company_id          :bigint           not null
#  saved_by_id         :bigint
#  school_id           :bigint           not null
#
# Indexes
#
#  index_school_registrations_on_academic_year_id  (academic_year_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (saved_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolRegistration < ApplicationRecord
  include TenantScoped
  audited associated_with: :school
  has_associated_audits

  STATUSES = %w[draft scheduled].freeze
  RUN_MODES = %w[arrive daily].freeze
  SESSIONS = { "AM" => "Morning", "PM" => "Afternoon", "CCA" => "CCA / ASA" }.freeze
  ASKS = { "cls" => "Class", "sidn" => "Student ID", "dob" => "Date of Birth", "med" => "Medical or Special Needs", "photo" => "Child Photo",
           "emerg" => "Emergency Contacts", "cca" => "CCA / ASA Days" }.freeze
  GRAD_MESSAGE = "Thank you for riding with us for the past [Years] years. It has been a great journey.".freeze

  belongs_to :school
  belongs_to :academic_year
  belongs_to :saved_by, class_name: "User", optional: true
  has_many :messages, class_name: "RegistrationMessage", dependent: :delete_all, inverse_of: :school_registration

  include MinuteTime
  minute_time :run_at

  validates :status, inclusion: { in: STATUSES }
  validates :run_mode, inclusion: { in: RUN_MODES }
  validates :academic_year_id, uniqueness: true

  def scheduled? = status == "scheduled"

  # Draft / Opens <date> / Renewals open / Opens to all <date> / Open / Closed (Convoy OS regStatus).
  def state(today = Date.current)
    return "draft" unless scheduled?
    return "upcoming" if today < renew_from
    return "renewals_open" if today <= renew_to
    return "general_upcoming" if today < general_from

    today <= general_to ? "open" : "closed"
  end

  def open_to_parents?(today = Date.current) = %w[renewals_open open].include?(state(today))
end
