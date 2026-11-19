# The driver's answer from the app (Account › Transport Company and invitations):
#   accept      pending → active; picked for this sign-in when none is picked yet
#   decline     pending → declined
#   disconnect  active  → past (the company's Remove: off its buses from today); profile and history stay with the driver
module DriverApp
  class Respond < ApplicationService
    ACTIONS = { "accept" => "accept", "decline" => "decline", "disconnect" => "remove" }.freeze

    def initialize(jwt:, member:, action:)
      @jwt = jwt
      @member = member
      @action = action.to_s
    end

    def call
      raise Error, "Unknown action" unless ACTIONS.key?(@action)

      check_status!
      ActsAsTenant.with_tenant(@member.company) do
        Drivers::Act.call(driver: @member, action: ACTIONS[@action], user: nil, company: @member.company)
      end
      ShareProfile.call(account: @jwt.driver_account, members: [ @member ]) if @action == "accept"
      if @action == "accept" && @jwt.membership_key.nil? then PickMembership.call(jwt: @jwt, member: @member)
      elsif @action == "disconnect" && @jwt.membership_key == DriverMembership.key(@member) then PickMembership.call(jwt: @jwt, member: nil)
      end
      @member
    end

    private

    # The app's own wording (Drivers::Act names the driver, as the OS row does), named as on the card: employer_name.
    def check_status!
      name = DriverMembership.employer_name(@member)
      if @action == "disconnect"
        return if @member.active?

        raise Error, @member.pending? ? "You have not joined #{name} yet" : "You no longer work with #{name}"
      end
      return if @member.pending?

      raise Error, @member.active? ? "You already work with #{name}" : "This invitation from #{name} is no longer open"
    end
  end
end
