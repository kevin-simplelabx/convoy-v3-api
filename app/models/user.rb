# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  avatar                 :string
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
#
# Indexes
#
#  index_users_on_company_id            (company_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_permissions           (permissions) USING gin
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A person who signs in to Convoy OS. Convoy Admins belong to no company and see every company read-only;
# company Admins (and owners) have every permission; members have the permissions they were given.
class User < ApplicationRecord
  PERMISSIONS = %w[users schools plans planview library vehicles finance finview finset vehfin].freeze

  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  mount_uploader :avatar, ImageUploader

  belongs_to :company, optional: true

  enum :role, { convoy_admin: "convoy_admin", admin: "admin", member: "member" }, validate: true
  enum :status, { active: "active", suspended: "suspended" }, validate: true

  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :name, presence: true
  validates :company, presence: true, unless: :convoy_admin?
  validates :company, absence: true, if: :convoy_admin?
  validate :permissions_known

  # Admins and owners hold every permission.
  def effective_permissions
    admin? || owner? ? PERMISSIONS : permissions
  end

  def can?(permission)
    effective_permissions.include?(permission.to_s)
  end

  # Devise: suspended users cannot sign in.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :suspended
  end

  private

  def permissions_known
    unknown = permissions - PERMISSIONS
    errors.add(:permissions, "has unknown values: #{unknown.join(', ')}") if unknown.any?
  end
end
