# Row buttons of Drivers and Operator Drivers (an admin records the driver's answer until the Driver app does):
#   resend       pending   → invite sent again
#   accept       pending   → active
#   decline      pending   → declined
#   reinvite     declined / past → pending, invite sent again
#   remove       active    → past: an own driver stops being default driver from today (and of any bus they were
#                             due to take over), an operator driver leaves their bus; the bus is kept as last_vehicle
#   delete       pending (cancel the invite) / declined / past → kept for history but gone from the lists
module Drivers
  class Act < ApplicationService
    ACTIONS = %w[resend accept decline reinvite remove delete].freeze

    def initialize(driver:, action:, user:, company:)
      @driver = driver
      @action = action.to_s
      @user = user
      @company = company
    end

    def call
      raise Error, "Unknown action" unless ACTIONS.include?(@action)

      @driver.transaction { public_send(@action) }
      @driver
    rescue AASM::InvalidTransition
      raise Error, "#{@driver.name} is #{@driver.status}, so this can't be done"
    end

    def resend
      raise AASM::InvalidTransition.new(@driver, :resend, :status) unless @driver.pending?

      @driver.update!(invited_at: Time.current)
      send_invite(:resend)
    end

    def accept = @driver.accept!
    def decline = @driver.decline!

    def reinvite
      @driver.reinvite!
      send_invite(:resend)
    end

    def remove
      raise AASM::InvalidTransition.new(@driver, :remove, :status) unless @driver.active?

      @driver.is_a?(Driver) ? release_own_buses : @driver.last_vehicle = @driver.vehicle
      @driver.remove!
    end

    def delete
      raise Error, "Remove #{@driver.name} first. Active drivers move to Past Drivers" if @driver.active?

      @driver.discard!
    end

    private

    def send_invite(kind)
      @driver.record_invite!(kind:, user: @user, message: InviteMessage.for(@driver, @company))
    end

    def release_own_buses
      today = Date.current
      bus = @driver.vehicle_on(today)
      @driver.last_vehicle = bus
      if bus
        entry = bus.driver_schedules.find_or_initialize_by(starts_on: today)
        entry.update!(driver: nil, created_by: @user)
      end
      @driver.upcoming_schedules.each { |s| s.update!(driver: nil, created_by: @user) }
    end
  end
end
