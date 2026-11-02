# A person at a Managed Client who signs in to the Client Portal (Client Users card), with a Client Portal role and the
# sites they act for. Super Admin, Admin and Finance Admin cover every site; the site roles cover only their sites.
# == Schema Information
#
# Table name: client_users
# Database name: primary
#
#  id                :bigint           not null, primary key
#  discarded_at      :datetime
#  email             :string           not null
#  name              :string           not null
#  role              :string           default("member"), not null
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_id         :bigint           not null
#  company_id        :bigint           not null
#  created_by_id     :bigint
#  portal_account_id :bigint           not null
#
# Indexes
#
#  index_client_users_on_client_id_and_email       (client_id,email) UNIQUE WHERE (discarded_at IS NULL)
#  index_client_users_on_company_id_and_client_id  (company_id,client_id)
#  index_client_users_on_created_by_id             (created_by_id)
#  index_client_users_on_email                     (email)
#  index_client_users_on_portal_account_id         (portal_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (portal_account_id => portal_accounts.id)
#
class ClientUser < ApplicationRecord
  include TenantScoped
  include Discard::Model
  audited associated_with: :client

  # Client Portal roles (logic/app-feed.js): label, one line, organisation-wide (every site).
  ROLES = {
    "super" => { label: "Super Admin", tag: "Everything, every site", wide: true },
    "adm" => { label: "Admin", tag: "Everything except removing a Super Admin", wide: true },
    "fin" => { label: "Finance Admin", tag: "Bookings, invoices and billing, every site", wide: true },
    "ssa" => { label: "Site Super Admin", tag: "Runs their sites: people, bookings, approvals", wide: false },
    "sa" => { label: "Site Admin", tag: "Like Site Super Admin, cannot remove one", wide: false },
    "sfin" => { label: "Site Finance", tag: "Bookings, invoices and billing for their sites", wide: false },
    "member" => { label: "Member", tag: "Books trips for their sites", wide: false }
  }.freeze

  belongs_to :client
  belongs_to :portal_account
  belongs_to :created_by, class_name: "User", optional: true
  has_many :user_sites, class_name: "ClientUserSite", dependent: :delete_all
  has_many :sites, through: :user_sites, source: :client_site

  enum :role, ROLES.keys.index_by(&:itself), validate: true

  normalizes :name, :title, with: ->(v) { v.to_s.squish.presence }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "looks wrong" }
  validates :email, uniqueness: { scope: :client_id, conditions: -> { kept }, message: "is already a user of this client" },
                    if: -> { kept? && will_save_change_to_email? }

  def self.ransackable_attributes(_auth = nil) = %w[name email role title]

  def role_label = ROLES.dig(role, :label)
  def wide? = ROLES.dig(role, :wide)
end
