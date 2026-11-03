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

      ActsAsTenant.with_tenant(@member.company) do
        Drivers::Act.call(driver: @member, action: ACTIONS[@action], user: nil, company: @member.company)
      end
      ShareProfile.call(account: @jwt.driver_account, members: [ @member ]) if @action == "accept"
      if @action == "accept" && @jwt.membership_key.nil? then PickMembership.call(jwt: @jwt, member: @member)
      elsif @action == "disconnect" && @jwt.membership_key == DriverMembership.key(@member) then PickMembership.call(jwt: @jwt, member: nil)
      end
      @member
    end
  end
end
