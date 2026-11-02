# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  all_schools            :boolean          default(TRUE), not null
#  avatar                 :string
#  discarded_at           :datetime
#  display_name           :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_seen_at           :datetime
#  mobile                 :string
#  name                   :string           not null
#  owner                  :boolean          default(FALSE), not null
#  permissions            :string           default([]), not null, is an Array
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("member"), not null
#  status                 :string           default("active"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  company_id             :bigint
#  created_by_id          :bigint
#
# Indexes
#
#  index_users_on_company_id                   (company_id)
#  index_users_on_company_id_and_discarded_at  (company_id,discarded_at)
#  index_users_on_created_by_id                (created_by_id)
#  index_users_on_live_email                   (email) UNIQUE WHERE (discarded_at IS NULL)
#  index_users_on_permissions                  (permissions) USING gin
#  index_users_on_reset_password_token         (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
# A person who signs in to Convoy OS. Convoy Admins belong to no company and see every company read-only.
# In a company: a Super Admin (owner) has every permission and manages Admins; a user with every permission is an
# Admin (role admin); anyone else is a member with the permissions they were given. Role names in Settings > Users
# come from the permissions (ROLE_PRESETS), they are not stored. Deleted users are discarded: their name stays on
# past records and their email can be used again.
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist
  include Discard::Model

  PERMISSIONS = %w[users schools plans planview library vehicles finance finview finset vehfin].freeze
  PERMISSION_LABELS = {
    "users" => "Users", "schools" => "Schools & Riders", "plans" => "Stops & Route Plans", "planview" => "View Route Plans",
    "library" => "Stop Library", "vehicles" => "Vehicles & Attendants", "finance" => "Fares & Billing",
    "finview" => "Finance Dashboard", "finset" => "Finance Settings", "vehfin" => "Vehicle Financials"
  }.freeze

  # Settings > Users > Start From a Role (and the View Role Permissions table).
  ROLE_PRESETS = [
    { id: "owner", name: "Super Admin", tag: "Owns the account. Manages Admins", owner: true, permissions: PERMISSIONS },
    { id: "admin", name: "Admin", tag: "Runs the account", permissions: PERMISSIONS },
    { id: "opsmgr", name: "Operations Manager", tag: "Runs operations, sees the money", permissions: %w[schools plans planview vehicles finview] },
    { id: "planner", name: "Planner", tag: "Plans and edits routes", permissions: %w[schools plans planview] },
    { id: "opsexec", name: "Operations Executive", tag: "Views plans, looks after riders", permissions: %w[schools planview] },
    { id: "libmgr", name: "Library Manager", tag: "Looks after shared stops", permissions: %w[plans library] },
    { id: "fleet", name: "Fleet Manager", tag: "Vehicles and staff", permissions: %w[vehicles] },
    { id: "finmgr", name: "Finance Manager", tag: "Runs billing and finance settings", permissions: %w[finance finview finset vehfin] },
    { id: "finops", name: "Finance Ops", tag: "Bills, payments and pay runs", permissions: %w[finance finview] },
    { id: "viewer", name: "Viewer", tag: "Looks only", permissions: [] }
  ].map(&:freeze).freeze

  # Devise without :validatable: the email is unique only among users not deleted (validated below).
  devise :database_authenticatable, :recoverable, :rememberable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  mount_uploader :avatar, ImageUploader

  audited except: %i[encrypted_password reset_password_token reset_password_sent_at remember_created_at last_seen_at]

  belongs_to :company, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :user_schools, dependent: :delete_all
  has_many :schools, through: :user_schools

  enum :role, { convoy_admin: "convoy_admin", admin: "admin", member: "member" }, validate: true
  enum :status, { active: "active", suspended: "suspended" }, validate: true

  normalizes :email, with: ->(v) { v.to_s.strip.downcase }
  normalizes :display_name, with: ->(v) { v.to_s.squish.presence }
  normalizes :mobile, with: ->(v) { v.blank? ? nil : Phonelib.parse(v).then { |p| p.valid? ? p.e164 : v.to_s.gsub(/[^\d+]/, "") } }
  normalizes :permissions, with: ->(v) { Array(v).map(&:to_s).uniq }

  scope :in_company, ->(company) { where(company:) }

  validates :name, presence: true
  validates :display_name, length: { maximum: 60 }
  validates :mobile, phone: { possible: true, allow_blank: true }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { conditions: -> { kept }, message: "is already used by another user" }, if: -> { will_save_change_to_email? && kept? }
  validates :password, presence: true, confirmation: true, if: :password_required?
  validates :password, length: { within: Devise.password_length }, allow_blank: true
  validates :company, presence: true, unless: :convoy_admin?
  validates :company, absence: true, if: :convoy_admin?
  validate :permissions_known

  def self.ransackable_attributes(_auth = nil) = %w[name email display_name status]
  def self.ransackable_associations(_auth = nil) = []

  # Sign in only as a user who is not deleted (a deleted user's email may belong to someone new).
  def self.find_for_authentication(conditions)
    kept.find_by(email: conditions[:email].to_s.strip.downcase)
  end

  # Admins and owners hold every permission.
  def effective_permissions
    admin? || owner? ? PERMISSIONS : permissions
  end

  def can?(permission)
    effective_permissions.include?(permission.to_s)
  end

  # Admins and Super Admins open every school; others every school when all_schools, else their user_schools.
  def every_school? = admin? || owner? || all_schools?

  def role_preset
    return ROLE_PRESETS.first if owner?

    ROLE_PRESETS.drop(1).find { |r| r[:permissions].sort == effective_permissions.sort }
  end

  def role_label = convoy_admin? ? "Convoy Admin" : role_preset&.dig(:name) || "Custom"

  def shown_name = display_name.presence || name

  def mobile_display = mobile && Phonelib.parse(mobile).then { |p| p.valid? ? p.international : mobile }

  # Devise: suspended and deleted users cannot sign in, and their tokens stop working.
  def active_for_authentication?
    super && active? && kept?
  end

  def inactive_message
    active? ? super : :suspended
  end

  private

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def permissions_known
    unknown = permissions - PERMISSIONS
    errors.add(:permissions, "has unknown values: #{unknown.join(', ')}") if unknown.any?
  end
end
