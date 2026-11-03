# The driver opened Trip Details: the run stops showing New (until its driver, bus or time changes; Sync clears it).
module DriverApp
  class MarkSeen < ApplicationService
    def initialize(occ:, member:)
      @occ = occ
      @member = member
    end

    def call
      @occ.update_columns(driver_seen_at: Time.current) if Runs.mine?(@occ, @member) && @occ.driver_seen_at.nil? # rubocop:disable Rails/SkipsModelValidations
      @occ
    end
  end
end
