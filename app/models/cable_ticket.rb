# A one-time pass to open the WebSocket (/cable?ticket=…) for one Driver app or Convoy App sign-in: valid TTL, used once,
# only its digest is kept. The app asks for it with its Bearer token right before connecting, so the long-lived JWT never
# goes into a URL. Signing out deletes the sign-in and its tickets (cascade).
#   token = CableTicket.issue!(jwt)      jwt = CableTicket.redeem(token)  # DriverJwt / AppJwt, or nil
# == Schema Information
#
# Table name: cable_tickets
# Database name: primary
#
#  id            :bigint           not null, primary key
#  expires_at    :datetime         not null
#  token_digest  :string           not null
#  used_at       :datetime
#  created_at    :datetime         not null
#  app_jwt_id    :bigint
#  driver_jwt_id :bigint
#
# Indexes
#
#  index_cable_tickets_on_app_jwt_id     (app_jwt_id)
#  index_cable_tickets_on_driver_jwt_id  (driver_jwt_id)
#  index_cable_tickets_on_expires_at     (expires_at)
#  index_cable_tickets_on_token_digest   (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (app_jwt_id => app_jwts.id) ON DELETE => cascade
#  fk_rails_...  (driver_jwt_id => driver_jwts.id) ON DELETE => cascade
#
class CableTicket < ApplicationRecord
  TTL = 60.seconds

  belongs_to :driver_jwt, optional: true
  belongs_to :app_jwt, optional: true

  scope :expired, -> { where(expires_at: ...Time.current) }

  def self.digest(token) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "cable-ticket:#{token}")

  def self.issue!(jwt)
    token = SecureRandom.urlsafe_base64(32)
    owner = jwt.is_a?(DriverJwt) ? { driver_jwt: jwt } : { app_jwt: jwt }
    create!(token_digest: digest(token), expires_at: TTL.from_now, **owner)
    token
  end

  # The sign-in of a live, unused ticket (the ticket is spent), or nil: unknown, expired, used, or signed out since.
  def self.redeem(token)
    return if token.blank?

    ticket = includes(:driver_jwt, :app_jwt).find_by(token_digest: digest(token.to_s))
    return unless ticket&.expires_at&.future?
    return unless where(id: ticket.id, used_at: nil).update_all(used_at: Time.current) == 1 # rubocop:disable Rails/SkipsModelValidations

    jwt = ticket.driver_jwt || ticket.app_jwt
    jwt if jwt&.exp&.future?
  end
end
