# Ends a Convoy Driver app sign-in: the company's app session closes and the token stops working.
module DriverApp
  class SignOut < ApplicationService
    def initialize(jwt:)
      @jwt = jwt
    end

    def call
      PickMembership.close_session(@jwt)
      @jwt.destroy!
    end
  end
end
