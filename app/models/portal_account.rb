# One person who signs in to the Client Portal (one email), for every client they are a user of (client_users).
# Created when a transport company adds them; they set their own password at first sign-in (one-time code by email).
# == Schema Information
#
# Table name: portal_accounts
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  email              :string           not null
#  encrypted_password :string           default(""), not null
#  last_sign_in_at    :datetime
#  name               :string
#  password_set_at    :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_portal_accounts_on_email  (email) UNIQUE
#
class PortalAccount < ApplicationRecord
  devise :database_authenticatable, :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  audited only: %i[email name password_set_at]

  has_many :client_users, dependent: :restrict_with_error
  has_many :portal_jwts, dependent: :delete_all
  has_many :sign_in_codes, class_name: "PortalSignInCode", dependent: :delete_all

  normalizes :email, with: ->(v) { v.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { within: Devise.password_length, message: "needs at least 8 characters" }, confirmation: true, allow_nil: true

  def password_set? = password_set_at.present?

  # The client accounts this person can open: client users not removed, of clients not deleted, in any company.
  def accounts
    ActsAsTenant.without_tenant do
      client_users.kept.joins(:client).merge(Client.kept).includes(client: :company).order("clients.name").to_a
    end
  end

  # The account for an email, created on first use.
  def self.for_email!(email, name: nil)
    find_or_create_by!(email: email.to_s.strip.downcase) { |a| a.name = name }
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
