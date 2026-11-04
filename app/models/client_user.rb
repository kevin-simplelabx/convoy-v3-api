# A person at a Managed Client who signs in to the Client Portal (Client Users card), with a Client Portal role and the
# sites they act for. Super Admin, Admin and Finance Admin cover every site; the site roles cover only their sites.
# == Schema Information
#
# Table name: client_users
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  discarded_at              :datetime
#  email                     :string           not null
#  name                      :string           not null
#  role                      :string           default("member"), not null
#  title                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  client_id                 :bigint           not null
#  client_team_id            :bigint
#  company_id                :bigint           not null
#  created_by_client_user_id :bigint
#  created_by_id             :bigint
#  manager_id                :bigint
#  portal_account_id         :bigint           not null
#
# Indexes
#
#  index_client_users_on_client_id_and_email        (client_id,email) UNIQUE WHERE (discarded_at IS NULL)
#  index_client_users_on_client_team_id             (client_team_id)
#  index_client_users_on_company_id_and_client_id   (company_id,client_id)
#  index_client_users_on_created_by_client_user_id  (created_by_client_user_id)
#  index_client_users_on_created_by_id              (created_by_id)
#  index_client_users_on_email                      (email)
#  index_client_users_on_manager_id                 (manager_id)
#  index_client_users_on_portal_account_id          (portal_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (client_team_id => client_teams.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_client_user_id => client_users.id) ON DELETE => nullify
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (manager_id => client_users.id) ON DELETE => nullify
#  fk_rails_...  (portal_account_id => portal_accounts.id)
#
class ClientUser < ApplicationRecord
  include TenantScoped
  include Discard::Model
  include ClientUserAccess
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
  belongs_to :created_by_client_user, class_name: "ClientUser", optional: true
  belongs_to :team, class_name: "ClientTeam", foreign_key: :client_team_id, optional: true, inverse_of: :users
  belongs_to :manager, class_name: "ClientUser", optional: true
  has_many :user_sites, class_name: "ClientUserSite", dependent: :delete_all
  has_many :sites, through: :user_sites, source: :client_site

  enum :role, ROLES.keys.index_by(&:itself), validate: true

  normalizes :name, :title, with: ->(v) { v.to_s.squish.presence }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "looks wrong" }
  validates :email, uniqueness: { scope: :client_id, conditions: -> { kept }, message: "is already a user of this client" },
                    if: -> { kept? && will_save_change_to_email? }

  validate :team_and_manager_of_client

  def self.ransackable_attributes(_auth = nil) = %w[name email role title]

  def role_label = ROLES.dig(role, :label)
  def wide? = ROLES.dig(role, :wide)

  # Their Manager: their own manager, else their team's (never themselves; removed people don't count).
  def manager_for_approval
    [ manager, team&.manager ].compact.find { |m| m.kept? && m.id != id }
  end

  private

  def team_and_manager_of_client
    errors.add(:team, "is not a team of this client") if will_save_change_to_client_team_id? && team && team.client_id != client_id
    return unless will_save_change_to_manager_id? && manager

    errors.add(:manager, "can't be themselves") if manager_id == id
    errors.add(:manager, "is not a user of this client") if manager.client_id != client_id || manager.discarded?
  end
end
