# A client's booking: up to 10 days (no more than 10 days apart), up to 10 trips a day, up to 10 vehicles a trip.
# Made on Trips > Bookings for a client who asked (later also from the Client Portal and the Convoy App).
# Each trip is approved, edited or rejected on its own; the booking's tab follows its trips.
# == Schema Information
#
# Table name: bookings
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  coordinator_email         :string
#  coordinator_name          :string           not null
#  coordinator_org           :string
#  coordinator_phone         :string
#  cost_centre               :string
#  created_by_name           :string
#  estimate_amount           :decimal(12, 2)   default(0.0), not null
#  lock_version              :integer          default(0), not null
#  notes                     :text
#  number                    :string           not null
#  po_number                 :string
#  service_for               :string
#  source                    :string           default("console"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  client_end_customer_id    :bigint
#  client_id                 :bigint           not null
#  client_site_id            :bigint
#  company_id                :bigint           not null
#  created_by_client_user_id :bigint
#  created_by_id             :bigint
#
# Indexes
#
#  index_bookings_on_client_end_customer_id     (client_end_customer_id)
#  index_bookings_on_client_id                  (client_id)
#  index_bookings_on_client_site_id             (client_site_id)
#  index_bookings_on_company_id                 (company_id)
#  index_bookings_on_company_id_and_created_at  (company_id,created_at)
#  index_bookings_on_company_id_and_number      (company_id,number) UNIQUE
#  index_bookings_on_created_by_client_user_id  (created_by_client_user_id)
#  index_bookings_on_created_by_id              (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_end_customer_id => client_end_customers.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (client_site_id => client_sites.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_client_user_id => client_users.id)
#  fk_rails_...  (created_by_id => users.id)
#
class Booking < ApplicationRecord
  include TenantScoped
  audited

  MAX_DAYS = 10
  MAX_SPAN_DAYS = 10
  MAX_TRIPS_A_DAY = 10
  MAX_ATTACHMENTS = 10
  TABS = %w[pending approved rejected completed].freeze
  WAITING = %w[pending awaiting_ack awaiting_client].freeze

  belongs_to :client
  belongs_to :client_site, optional: true
  belongs_to :client_end_customer, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  include ActorStamp
  actor_stamp :created
  has_many :days, -> { order(:date) }, class_name: "BookingDay", dependent: :destroy, inverse_of: :booking
  has_many :trips, class_name: "BookingTrip", dependent: :destroy, inverse_of: :booking
  has_many :attachments, class_name: "BookingAttachment", dependent: :destroy, inverse_of: :booking
  has_many :cancel_requests, -> { order(:requested_at) }, class_name: "BookingCancelRequest", dependent: :destroy, inverse_of: :booking
  has_many :events, class_name: "BookingEvent", dependent: :delete_all, inverse_of: :booking
  has_one :approval, class_name: "BookingApproval", dependent: :destroy, inverse_of: :booking

  enum :source, { console: "console", portal: "portal", app: "app" }, prefix: :from, validate: true

  validates :number, presence: true
  validates :coordinator_name, presence: true
  validates :coordinator_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Tab of each booking, from its trips (same rules as #tab):
  # pending — a trip waits (for us or the client); rejected — no trip approved; completed — every approved trip's date
  # has passed; approved — otherwise.
  TAB_SQL = <<~SQL.squish.freeze
    CASE WHEN s.waiting THEN 'pending' WHEN s.approved = 0 THEN 'rejected'
         WHEN s.last_approved < :today THEN 'completed' ELSE 'approved' END
  SQL
  STATS_SQL = <<~SQL.squish.freeze
    JOIN (SELECT bt.booking_id, BOOL_OR(bt.status IN ('pending', 'awaiting_ack', 'awaiting_client')) AS waiting,
                 COUNT(*) FILTER (WHERE bt.status = 'approved') AS approved,
                 MAX(bd.date) FILTER (WHERE bt.status = 'approved') AS last_approved
          FROM booking_trips bt JOIN booking_days bd ON bd.id = bt.booking_day_id GROUP BY bt.booking_id) s ON s.booking_id = bookings.id
  SQL

  scope :with_tab, ->(today = Date.current) { joins(STATS_SQL).select("bookings.*", "#{sanitize_sql_array([ TAB_SQL, { today: } ])} AS tab_value") }
  scope :in_tab, ->(tab, today = Date.current) { joins(STATS_SQL).where("#{sanitize_sql_array([ TAB_SQL, { today: } ])} = ?", tab) }
  scope :search, lambda { |q|
    next all if q.blank?

    left_joins(:client).where(
      "bookings.number ILIKE :q OR bookings.coordinator_name ILIKE :q OR bookings.coordinator_email ILIKE :q " \
      "OR bookings.coordinator_phone ILIKE :q OR clients.name ILIKE :q", q: "%#{sanitize_sql_like(q.to_s.strip)}%"
    )
  }

  def self.tab_counts(scope, today = Date.current)
    counts = scope.joins(STATS_SQL).group(Arel.sql(sanitize_sql_array([ TAB_SQL, { today: } ]))).count
    TABS.index_with { |t| counts[t].to_i }
  end

  def tab(today = Date.current)
    return self[:tab_value] if has_attribute?(:tab_value)

    statuses = trips.map(&:status)
    return "pending" if statuses.intersect?(WAITING)

    approved = trips.select(&:approved?)
    return "rejected" if approved.empty?

    approved.map { |t| t.day.date }.max < today ? "completed" : "approved"
  end

  # Status shown on the booking: a waiting trip first, else Unassigned / Assigned (approved trips, from
  # Bookings::Assignment), Completed, Rejected or Cancelled.
  def status_label(today = Date.current)
    statuses = trips.map(&:status)
    return "Pending Client Acknowledgement" if statuses.include?("awaiting_ack")
    return "Awaiting Client Approval" if statuses.include?("awaiting_client")
    return "Ready for Approval" if statuses.include?("pending")

    case tab(today)
    when "rejected" then statuses.all?("cancelled") ? "Cancelled" : "Rejected"
    when "completed" then "Completed"
    else trips.select(&:approved?).any?(&:unassigned) ? "Unassigned" : "Assigned"
    end
  end

  # Estimate of the booking: its trips but the rejected and cancelled ones.
  def estimate_total = trips.reject { |t| t.rejected? || t.cancelled? }.sum(&:estimate_amount)

  # Booking ID: company code, 2-digit year, 6-digit running number for the year (SD26000141).
  def self.next_number(company, date = Date.current)
    yy = date.strftime("%y")
    "#{company.code.upcase}#{yy}#{CompanySequence.next!("booking_#{yy}").to_s.rjust(6, '0')}"
  end
end
