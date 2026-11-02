# == Schema Information
#
# Table name: clients
# Database name: primary
#
#  id                :bigint           not null, primary key
#  billing_address   :text
#  code              :string           not null
#  contact_name      :string
#  discarded_at      :datetime
#  email             :string
#  kind              :string           default("company"), not null
#  name              :string           not null
#  on_time_allowance :integer          default(3), not null
#  phone             :string
#  uen               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  rate_card_id      :bigint
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
  belongs_to :rate_card, optional: true

  enum :kind, { company: "company", individual: "individual", transport_company: "transport_company" }, validate: true

  accepts_nested_attributes_for :sites, :end_customers, :pickup_points, allow_destroy: true

  before_validation :assign_code, on: :create
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }

  validates :name, presence: true, uniqueness: { scope: :company_id, conditions: -> { kept } }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :on_time_allowance, numericality: { only_integer: true, in: 0..15 }
  validate :individual_reachable

  def self.ransackable_attributes(_auth = nil) = %w[name code kind email uen]

  # Main contractor: the trips we run for them are sub-contracted.
  def main_contractor? = transport_company?

  private

  def assign_code
    self.code ||= format("CL%05d", CompanySequence.next!(:client_code))
  end

  def individual_reachable
    errors.add(:base, "An individual needs a mobile or email") if individual? && phone.blank? && email.blank?
  end
end
