# Switch Company: the company (active membership) this sign-in works in, or none. Each pick opens a Driver app session
# in that company (Ops Control reads it) and closes the one before.
module DriverApp
  class PickMembership < ApplicationService
    def initialize(jwt:, member:)
      @jwt = jwt
      @member = member
    end

    def call
      raise Error, "You can only switch to a company you work for" if @member && !(@member.active? && @member.driver_account_id == @jwt.driver_account_id)

      self.class.close_session(@jwt)
      session = @member && ActsAsTenant.with_tenant(@member.company) do
        DriverAppSession.create!(company: @member.company, @member.model_name.singular => @member, signed_in_at: Time.current, last_seen_at: Time.current)
      end
      @jwt.update!(driver: @member.is_a?(Driver) ? @member : nil, operator_driver: @member.is_a?(OperatorDriver) ? @member : nil,
                   driver_app_session: session)
      @jwt
    end

    def self.close_session(jwt)
      session = jwt.driver_app_session_id && ActsAsTenant.without_tenant { DriverAppSession.find_by(id: jwt.driver_app_session_id) }
      session&.update_columns(signed_out_at: Time.current) unless session&.signed_out_at # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
