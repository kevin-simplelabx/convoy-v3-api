# == Schema Information
#
# Table name: schools
# Database name: primary
#
#  id               :bigint           not null, primary key
#  address          :text
#  lat              :decimal(10, 7)
#  lng              :decimal(10, 7)
#  name             :string           not null
#  postal           :string
#  short_name       :string
#  stops_changed_at :timestamptz
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  calendar_id      :bigint
#  client_id        :bigint
#  company_id       :bigint           not null
#
# Indexes
#
#  index_schools_on_calendar_id          (calendar_id)
#  index_schools_on_client_id            (client_id) UNIQUE WHERE (client_id IS NOT NULL)
#  index_schools_on_company_id           (company_id)
#  index_schools_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#
# A school whose buses we run (School Bus). The Scheduler shows its routes on the school days of its academic years.
# calendar (Clients › School Calendar) is kept for the client record; School Bus runs follow the academic years.
class School < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :client, optional: true
  belongs_to :calendar, optional: true
  has_many :plans, class_name: "SchoolPlan", dependent: :destroy
  has_many :user_schools, dependent: :delete_all
  has_many :route_labels, class_name: "SchoolRouteLabel", dependent: :delete_all
  has_many :rider_datasets, -> { order(:effective_from, :id) }, dependent: :destroy, inverse_of: :school
  has_many :riders, class_name: "SchoolRider", dependent: :delete_all
  has_many :academic_years, -> { order(:starts_on) }, dependent: :destroy, inverse_of: :school
  has_many :setup_locks, dependent: :delete_all
  has_many :levels, -> { order(:position) }, class_name: "SchoolLevel", dependent: :delete_all, inverse_of: :school
  has_one :attendant_policy, class_name: "SchoolAttendantPolicy", dependent: :delete
  has_many :fare_adjustments, dependent: :delete_all
  has_many :policy_versions, -> { order(:effective_on, :version) }, class_name: "SchoolPolicyVersion", dependent: :destroy, inverse_of: :school
  has_one :payment_method, class_name: "SchoolPaymentMethod", dependent: :delete
  has_one :operator_pay, class_name: "SchoolOperatorPay", dependent: :delete
  has_many :school_stops, dependent: :destroy
  has_many :rider_point_links, dependent: :delete_all
  has_many :rider_assignments, dependent: :delete_all
  has_many :route_charges, dependent: :delete_all
  has_many :families, dependent: :destroy
  has_many :bus_requests, dependent: :destroy
  has_one :cca_ride_setting, dependent: :delete
  has_many :cca_bookings, dependent: :delete_all
  has_many :cca_off_days, dependent: :delete_all
  has_many :cca_credits, dependent: :delete_all
  has_many :family_riders, dependent: :delete_all
  has_many :route_charges_without_route, -> { where(school_route_id: nil).order(:starts_on) }, class_name: "RouteCharge", inverse_of: :school
  has_many :bus_size_rates, -> { order(:bus_type) }, class_name: "SchoolBusSizeRate", dependent: :delete_all, inverse_of: :school
  has_many :school_bills, dependent: :destroy
  has_many :school_documents, dependent: :destroy
  has_many :school_bill_runs, dependent: :delete_all
  has_many :school_payouts, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :postal, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, allow_nil: true
  validates :client_id, uniqueness: true, allow_nil: true

  def short = short_name.presence || name

  # Route Labels of AM, PM and CCA / ASA: the saved ones, or the defaults (unsaved).
  def labels
    saved = route_labels.index_by(&:session)
    SchoolRouteLabel::SESSIONS.map { |k| saved[k] || route_labels.build(session: k, **SchoolRouteLabel::DEFAULTS[k]) }
  end
end
