# A Bus Service Request (Convoy OS requests.js): a new service or renewal for an academic year, a change of address,
# a change of service or a stop, sent by a parent in the Convoy App (source app) or added in Convoy OS on their behalf
# (console). Statuses use the app's words; Lapsed and Stopped are read from the dates, not stored. Mid-year requests
# (sent after the year's service started) are acknowledged with an answer date, which can move with a reason.
# == Schema Information
#
# Table name: bus_requests
# Database name: primary
#
#  id               :bigint           not null, primary key
#  ack_note         :text
#  ack_plan_weeks   :integer
#  acked_at         :timestamptz
#  address          :string
#  adds             :boolean          default(FALSE), not null
#  agree            :string
#  am               :boolean          default(TRUE), not null
#  answer_by        :date
#  birth_date       :date
#  cca              :boolean          default(FALSE), not null
#  cca_days         :string           default([]), not null, is an Array
#  child_name       :string           not null
#  class_name       :string
#  code             :string           not null
#  confirm_note     :text
#  confirmed_at     :timestamptz
#  current_fare     :decimal(12, 2)
#  earliest_on      :date
#  early            :boolean          default(FALSE), not null
#  effective_on     :date
#  ended_at         :timestamptz
#  ended_on         :date
#  estimate         :decimal(12, 2)
#  fee_paid         :boolean          default(TRUE), not null
#  fix_note         :string
#  fix_why          :string
#  kind             :string           default("new"), not null
#  km               :decimal(6, 2)
#  last_on          :date
#  lat              :float
#  level            :string
#  level_moved_on   :date
#  lng              :float
#  medical          :text
#  mid              :boolean          default(FALSE), not null
#  new_stop         :string
#  notice_n         :integer
#  notice_unit      :string
#  offer_by         :timestamptz
#  old_address      :string
#  old_am           :boolean
#  old_cca          :boolean
#  old_pm           :boolean
#  old_postal       :string
#  parent_email     :string
#  parent_name      :string
#  parent_phone     :string
#  pay_to           :date
#  plan_lines       :string           default([]), not null, is an Array
#  planned_at       :timestamptz
#  planned_ok       :boolean
#  pm               :boolean          default(TRUE), not null
#  policy_version   :integer
#  postal           :string
#  quote_amount     :decimal(12, 2)
#  quote_base       :decimal(12, 2)
#  quote_note       :text
#  quote_unit       :string
#  quoted_at        :timestamptz
#  reason           :string
#  renew            :boolean          default(FALSE), not null
#  rider_patched_on :date
#  same             :boolean          default(FALSE), not null
#  source           :string           default("app"), not null
#  start_on         :date
#  start_when       :string
#  status           :string           default("Requested"), not null
#  stop_why         :string
#  stop_why_note    :string
#  student_no       :string
#  submitted_at     :timestamptz      not null
#  tags             :string           default([]), not null, is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint
#  acked_by_id      :bigint
#  company_id       :bigint           not null
#  confirmed_by_id  :bigint
#  ended_by_id      :bigint
#  family_id        :bigint
#  quoted_by_id     :bigint
#  school_id        :bigint           not null
#  school_rider_id  :bigint
#
# Indexes
#
#  index_bus_requests_on_academic_year_id               (academic_year_id)
#  index_bus_requests_on_company_id_and_code            (company_id,code) UNIQUE
#  index_bus_requests_on_family_id                      (family_id)
#  index_bus_requests_on_school_id                      (school_id)
#  index_bus_requests_on_school_id_and_kind_and_status  (school_id,kind,status)
#  index_bus_requests_on_school_rider_id                (school_rider_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id)
#  fk_rails_...  (acked_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (confirmed_by_id => users.id)
#  fk_rails_...  (ended_by_id => users.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => nullify
#  fk_rails_...  (quoted_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => nullify
#
class BusRequest < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  KINDS = %w[new adr svc stop].freeze
  SOURCES = %w[app console sample].freeze
  STATUSES = [ "Requested", "Under Review", "Accepted", "Active", "Waitlisted", "Declined", "Withdrawn", "Not Agreed", "Stopping", "Stopped" ].freeze
  STOP_WHY = { "leave" => "Leaving the school", "move" => "Moving house", "noneed" => "No longer needed" }.freeze
  TONES = { "Requested" => "info", "Under Review" => "info", "Accepted" => "success", "Active" => "success", "Waitlisted" => "warning",
            "Declined" => "danger", "Lapsed" => "neutral", "Withdrawn" => "neutral", "Not Agreed" => "warning", "Stopping" => "warning",
            "Stopped" => "neutral" }.freeze
  STARTS = %w[asap first pref fixed].freeze
  FIX_WHY = { "move" => "moving house", "ready" => "not ready to start before then" }.freeze

  belongs_to :school
  belongs_to :academic_year, optional: true
  belongs_to :family, optional: true
  belongs_to :school_rider, optional: true
  belongs_to :acked_by, class_name: "User", optional: true
  belongs_to :quoted_by, class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true
  belongs_to :ended_by, class_name: "User", optional: true
  has_many :plan_changes, class_name: "SchoolPlanChange", dependent: :nullify
  has_one :first_bill, -> { where(kind: "first") }, class_name: "SchoolBill", dependent: :nullify, inverse_of: :bus_request
  has_many :places, -> { order(:session) }, class_name: "BusRequestPlace", dependent: :delete_all, inverse_of: :bus_request
  has_many :events, -> { order(:at, :id) }, class_name: "BusRequestEvent", dependent: :delete_all, inverse_of: :bus_request
  has_many :answer_moves, -> { order(:moved_at, :id) }, class_name: "BusRequestAnswerMove", dependent: :delete_all, inverse_of: :bus_request

  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :kind, inclusion: { in: KINDS }
  validates :source, inclusion: { in: SOURCES }
  validates :status, inclusion: { in: STATUSES }
  validates :start_when, inclusion: { in: STARTS }, allow_nil: true
  validates :child_name, presence: true

  before_validation { self.code ||= format("REQ-%04d", CompanySequence.next!(:bus_request)) }

  scope :of_kind, ->(kind) { where(kind:) }
  scope :not_withdrawn, -> { where.not(status: "Withdrawn") }

  # The status as people read it: an accepted new request not paid by the end of the offer has Lapsed; a stop past its
  # last day has Stopped.
  def live_status(now = Time.current)
    return "Lapsed" if status == "Accepted" && kind == "new" && offer_by && offer_by < now && !first_bill&.paid?
    return "Stopped" if status == "Stopping" && last_on && last_on < now.to_date

    status
  end

  def renewing? = tags.include?("Renewing")
  def waiting_for_parent? = status == "Accepted" && agree == "wait"
  def stop_reason = stop_why == "other" ? stop_why_note.presence || "Other reason" : STOP_WHY.fetch(stop_why.to_s, "Not given")

  # Two ways, Morning only or Afternoon only, plus the CCA bus.
  def self.service_text(am, pm, cca)
    base = am && pm ? "Two ways" : am ? "Morning only" : pm ? "Afternoon only" : "Not given"
    cca ? "#{base} + CCA bus" : base
  end
  def fixed_why = fix_why == "other" ? fix_note.to_s.strip : FIX_WHY[fix_why].to_s

  def log!(text, by:, at: Time.current)
    user = by.is_a?(User) ? by : nil
    events.create!(at:, by_name: user&.name || by.to_s, user:, text:)
  end
end
