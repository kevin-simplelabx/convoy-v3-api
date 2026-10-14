class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :validatable

  belongs_to :company, optional: true

  ROLES = %w[super admin user].freeze
  ALL_PERMISSIONS = %w[users schools plans library vehicles].freeze

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  def super_admin?
    role == "super"
  end

  def all_permissions?
    permissions.sort == ALL_PERMISSIONS.sort
  end

  def effective_permissions
    return ALL_PERMISSIONS if role.in?(%w[admin super])
    permissions
  end

  def has_permission?(perm)
    role.in?(%w[admin super]) || permissions.include?(perm)
  end
end
