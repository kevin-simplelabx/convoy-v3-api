# == Schema Information
#
# Table name: client_sites
# Database name: primary
#
#  id              :bigint           not null, primary key
#  address         :text
#  billing_address :text
#  billing_name    :string
#  billing_uen     :string
#  lat             :decimal(10, 7)
#  lng             :decimal(10, 7)
#  name            :string           not null
#  own_billing     :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :bigint           not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_id       :bigint
#
# Indexes
#
#  index_client_sites_on_client_id           (client_id)
#  index_client_sites_on_client_id_and_name  (client_id,name) UNIQUE
#  index_client_sites_on_company_id          (company_id)
#  index_client_sites_on_created_by_id       (created_by_id)
#  index_client_sites_on_school_id           (school_id) UNIQUE WHERE (school_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
# A place of a client (office, campus, centre). Corporate Shuttle stops can be marked as a site.
class ClientSite < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client, inverse_of: :sites
  belongs_to :school, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :billing_contacts, -> { order(:position, :id) }, class_name: "ClientBillingContact", as: :billable, dependent: :delete_all
  # Kept trips block Remove (check_in_use); deleted trips and past bookings just lose the site.
  has_many :trip_stops, dependent: :nullify
  has_many :trips, dependent: :nullify
  has_many :bookings, dependent: :nullify
  has_many :client_user_sites, dependent: :delete_all

  normalizes :name, :billing_name, with: ->(v) { v.to_s.squish.presence }
  normalizes :billing_uen, with: ->(v) { Uen.normalize(v) }

  validates :name, presence: true, uniqueness: { scope: :client_id, case_sensitive: false, message: "is already a site of this client" }
  validates :billing_name, presence: { message: "is needed: the legal name the site is billed as" }, if: :own_billing?
  validates :billing_uen, format: { with: Uen::FORMAT, message: Uen::MESSAGE }, allow_nil: true
  validate :school_free, if: -> { school_id.present? && will_save_change_to_school_id? }
  before_destroy :check_in_use, prepend: true

  # Trips (not deleted) for this site or with a stop marked as this site: "On 2 shuttle trips".
  def shuttle_trips_count
    Trip.kept.where(client_site_id: id).or(Trip.kept.where(id: TripStop.where(client_site_id: id).select(:trip_id))).count
  end

  private

  def school_free
    errors.add(:school, "is already linked to #{school.client.name}") if school.client_id
  end

  def check_in_use
    n = shuttle_trips_count
    return if n.zero?

    errors.add(:base, "#{name} is on #{n} shuttle #{'trip'.pluralize(n)}. Unmark it in Stop Details first")
    throw :abort
  end
  validates :lat, numericality: { in: -90..90 }, allow_nil: true
  validates :lng, numericality: { in: -180..180 }, allow_nil: true
end
