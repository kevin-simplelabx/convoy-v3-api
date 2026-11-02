# Invite Driver / Invite Operator Driver: a pending driver and the invite recorded to their mobile.
module Drivers
  class Invite < ApplicationService
    def initialize(driver:, user:, company:)
      @driver = driver
      @user = user
      @company = company
    end

    def call
      @driver.transaction do
        @driver.status = :pending
        @driver.save!
        @driver.record_invite!(kind: :invite, user: @user, message: InviteMessage.for(@driver, @company))
      end
      @driver
    end
  end
end
