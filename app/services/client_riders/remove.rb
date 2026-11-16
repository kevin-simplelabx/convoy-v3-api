# The office removes a staff shuttle rider (Managed Clients › Staff Riders): the link ends in the Convoy App at once. The
# row stays as "removed", so the same work email is not invited again by the domain match.
module ClientRiders
  class Remove < ApplicationService
    def initialize(rider:, actor:)
      @rider = rider
      @actor = actor
    end

    def call
      @rider.with_lock do
        raise Error, "This rider is already removed" if @rider.removed?

        @rider.update!(status: "removed", removed_by: @actor, responded_at: Time.current)
      end
      @rider
    end
  end
end
