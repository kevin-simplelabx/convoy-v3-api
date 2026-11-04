# == Schema Information
#
# Table name: clients
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  billing_address    :text
#  billing_name       :string
#  brand_color        :string
#  brand_logo         :string
#  brand_logo_ratio   :decimal(5, 2)
#  code               :string           not null
#  contact_name       :string
#  default_po         :string
#  discarded_at       :datetime
#  email              :string
#  kind               :string           default("company"), not null
#  late_cancel_hours  :integer          default(24), not null
#  name               :string           not null
#  on_time_allowance  :integer          default(3), not null
#  payment_terms_days :integer
#  phone              :string
#  uen                :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  rate_card_id       :bigint
#
# Indexes
#
#  index_clients_on_company_id           (company_id)
#  index_clients_on_company_id_and_code  (company_id,code) UNIQUE
#  index_clients_on_company_id_and_name  (company_id,name) UNIQUE WHERE (discarded_at IS NULL)
#  index_clients_on_discarded_at         (discarded_at)
#  index_clients_on_rate_card_id         (rate_card_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_id => rate_cards.id)
#
# A Managed Client: a company, an individual, or a transport company that gives us work (we are the sub-contractor).
class Client < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits
  include Discard::Model

  has_many :sites, class_name: "ClientSite", dependent: :destroy, inverse_of: :client
  has_many :end_customers, class_name: "ClientEndCustomer", dependent: :destroy, inverse_of: :client
  has_many :pickup_points, class_name: "ClientPickupPoint", dependent: :destroy, inverse_of: :client
  has_many :bookings, dependent: :restrict_with_error
  has_many :trips, dependent: :restrict_with_error
  has_one :school, dependent: :nullify
  has_many :billing_contacts, -> { order(:position, :id) }, class_name: "ClientBillingContact", as: :billable, dependent: :delete_all
  has_many :bookable_vehicle_types, class_name: "ClientBookableVehicleType", dependent: :delete_all
  has_many :users, class_name: "ClientUser", dependent: :restrict_with_error
  has_many :teams, class_name: "ClientTeam", dependent: :delete_all
  belongs_to :rate_card, optional: true

  # Client Portal › Logo and Colour: the logo (with its width / height for the strip) and a colour line.
  mount_uploader :brand_logo, BrandLogoUploader

  enum :kind, { company: "company", individual: "individual", transport_company: "transport_company" }, validate: true

  accepts_nested_attributes_for :sites, :end_customers, :pickup_points, allow_destroy: true

  before_validation :assign_code, on: :create
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }
  normalizes :uen, with: ->(v) { Uen.normalize(v) }
  normalizes :name, with: ->(v) { v.to_s.squish }
  normalizes :billing_name, with: ->(v) { v.to_s.squish.presence }
  normalizes :brand_color, with: ->(v) { v.to_s.strip.upcase.presence }

  validates :name, presence: true, uniqueness: { scope: :company_id, conditions: -> { kept } }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :uen, format: { with: Uen::FORMAT, message: Uen::MESSAGE }, allow_nil: true
  validates :on_time_allowance, numericality: { only_integer: true, in: 0..15 }
  validates :payment_terms_days, numericality: { only_integer: true, in: 0..365 }, allow_nil: true
  validates :late_cancel_hours, numericality: { only_integer: true, in: 0..720 }
  validates :brand_color, format: { with: /\A#\h{6}\z/, message: "Enter the colour as a hex code like #004F59" }, allow_nil: true
  validate :individual_reachable

  before_save :measure_brand_logo, if: :brand_logo_changed?

  def self.ransackable_attributes(_auth = nil) = %w[name code kind email uen]

  # Invoice terms (days): set on the client, else 0 for individuals ("Due on receipt") and 30 for others.
  def terms_days = payment_terms_days || (individual? ? 0 : 30)

  # The legal name invoices are billed to (Billing Name in Finance, Legal Name in the Client Portal), else the name.
  def bill_name = billing_name || name

  # Main contractor: the trips we run for them are sub-contracted.
  def main_contractor? = transport_company?

  # What stops Delete Client: trips still running (not deleted, not ended) and bookings still open (waiting or approved).
  def delete_blockers(today = Date.current)
    trips_left = trips.kept.running_on(today).count
    bookings_left = bookings.in_tab("pending", today).count + bookings.in_tab("approved", today).count
    [ (trips_left.positive? ? "#{trips_left} #{'trip'.pluralize(trips_left)} still running" : nil),
      (bookings_left.positive? ? "#{bookings_left} open #{'booking'.pluralize(bookings_left)}" : nil) ].compact
  end

  private

  def assign_code
    self.code ||= format("CL%05d", CompanySequence.next!(:client_code))
  end

  def measure_brand_logo
    self.brand_logo_ratio = brand_logo.present? ? BrandLogoUploader.ratio(brand_logo) : nil
  end

  def individual_reachable
    errors.add(:base, "An individual needs a mobile or email") if individual? && phone.blank? && email.blank?
  end
end
