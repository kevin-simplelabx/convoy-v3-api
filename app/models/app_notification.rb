# == Schema Information
#
# Table name: app_notifications
# Database name: primary
#
#  id              :bigint           not null, primary key
#  banner_until    :datetime
#  body            :text             not null
#  dedupe_key      :string           not null
#  dismissed_at    :datetime
#  kind            :string           not null
#  occurrence_date :date
#  pushed_at       :datetime
#  read_at         :datetime
#  target          :string
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  app_account_id  :bigint           not null
#  company_id      :bigint
#  dependant_id    :bigint
#  notice_id       :bigint
#  occurrence_id   :bigint
#  target_id       :bigint
#  trip_id         :bigint
#
# Indexes
#
#  index_app_notifications_banners                           (app_account_id,banner_until) WHERE ((banner_until IS NOT NULL) AND (dismissed_at IS NULL))
#  index_app_notifications_on_app_account_id                 (app_account_id)
#  index_app_notifications_on_app_account_id_and_created_at  (app_account_id,created_at)
#  index_app_notifications_on_app_account_id_and_dedupe_key  (app_account_id,dedupe_key) UNIQUE
#  index_app_notifications_on_company_id                     (company_id)
#  index_app_notifications_on_dependant_id                   (dependant_id)
#  index_app_notifications_on_notice_id                      (notice_id)
#  index_app_notifications_on_trip_id                        (trip_id)
#  index_app_notifications_unread                            (app_account_id) WHERE (read_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (app_account_id => app_accounts.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (dependant_id => dependants.id) ON DELETE => nullify
#  fk_rails_...  (notice_id => notices.id) ON DELETE => nullify
#  fk_rails_...  (trip_id => trips.id) ON DELETE => nullify
#
# One line in a Convoy App account's inbox (the Alerts tab), written by services when something happens (ConvoyApp::Alerts):
# School Bus (trip started, bus 10 min away, running late, different bus, boarded / alighted, notice), shuttle (bus change,
# cancelled, no / changed service, notice), a Family bill issued, a bus request answered, a booking confirmed / changed /
# declined / cancelled, an organisation or Family invite. `dedupe_key` makes every alert fire once per account;
# `occurrence_id` + `occurrence_date` point at the run (partitioned table, so no foreign key); `target` + `target_id` say
# what a tap opens; `banner_until` keeps it on Home as a banner until then (unless dismissed). `pushed_at`: when it
# reached a phone as a push (Push::AppAlerts).
class AppNotification < ApplicationRecord
  # kind => [icon, tone, filter group (delays / notices / nil), chip]. Tone: info (teal), warning (orange), success, danger.
  CATALOGUE = {
    "shuttle_bus_change" => [ "swap_horiz", "warning", nil, nil ],
    "shuttle_cancelled" => [ "event_busy", "danger", nil, nil ],
    "shuttle_service_day" => [ "event_note", "warning", nil, nil ],
    "shuttle_notice" => [ "campaign", "info", "notices", nil ],
    "school_started" => [ "directions_bus", "info", nil, "track_bus" ],
    "school_near" => [ "near_me", "info", nil, "track_bus" ],
    "school_late" => [ "schedule", "warning", "delays", "track_bus" ],
    "school_bus_change" => [ "swap_horiz", "warning", nil, "track_bus" ],
    "school_boarded" => [ "check_circle", "success", nil, nil ],
    "school_alighted" => [ "check_circle", "success", nil, nil ],
    "school_notice" => [ "campaign", "info", "notices", "school_calendar" ],
    "bill_issued" => [ "receipt_long", "info", nil, nil ],
    "request_update" => [ "assignment", "info", nil, nil ],
    "booking_confirmed" => [ "check_circle", "success", nil, nil ],
    "booking_changed" => [ "edit_note", "warning", nil, nil ],
    "booking_declined" => [ "cancel", "danger", nil, nil ],
    "booking_cancelled" => [ "event_busy", "danger", nil, nil ],
    "booking_cancel_declined" => [ "event_available", "warning", nil, nil ],
    "invite_family" => [ "family_restroom", "info", nil, nil ],
    "invite_employer" => [ "apartment", "info", nil, nil ],
    "invite_bookings" => [ "apartment", "info", nil, nil ]
  }.freeze
  KINDS = CATALOGUE.keys.freeze
  FILTERS = { "delays" => KINDS.select { CATALOGUE[it][2] == "delays" }, "notices" => KINDS.select { CATALOGUE[it][2] == "notices" } }.freeze
  # What a tap opens: live (Live Tracking, target_id = dependant), school_calendar, shuttle_route (target_id = employer link,
  # trip_id = route), booking, school_request, fee_invoice (bill), household_invitations, organisations.
  TARGETS = %w[live school_calendar shuttle_route booking school_request fee_invoice household_invitations organisations].freeze

  belongs_to :app_account
  belongs_to :company, optional: true
  belongs_to :trip, optional: true
  belongs_to :dependant, optional: true
  belongs_to :notice, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :target, inclusion: { in: TARGETS }, allow_nil: true
  validates :title, :body, :dedupe_key, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :newest, -> { order(created_at: :desc, id: :desc) }
  scope :filtered, ->(filter) { FILTERS.key?(filter.to_s) ? where(kind: FILTERS[filter.to_s]) : all }
  # Home banners in force: not dismissed, banner_until still ahead.
  scope :banners_at, ->(now) { where(dismissed_at: nil).where("banner_until > ?", now) }

  def icon = CATALOGUE.dig(kind, 0)
  def tone = CATALOGUE.dig(kind, 1)
  def filter_group = CATALOGUE.dig(kind, 2)
  def chip = CATALOGUE.dig(kind, 3)
end
