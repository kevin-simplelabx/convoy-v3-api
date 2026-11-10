# Remove a rider added by hand. Refused while anything still uses the rider (a family, a stop, an absence, a CCA booking,
# a bus request or a bill): those are removed first, so no record is left pointing at nothing.
module SchoolRiders
  class Remove < ApplicationService
    def initialize(rider:)
      @rider = rider
    end

    def call
      raise Error, "Riders from an uploaded list leave with the next upload" unless @rider.manual?

      used = uses
      raise Error, "#{@rider.name} is still used by #{used.to_sentence}: remove that first" if used.any?

      @rider.destroy!
    end

    private

    def uses
      school = @rider.school
      rid = @rider.rid
      {
        "a family" => FamilyRider.where(school:, rid:),
        "a stop" => RiderAssignment.where(school:, rid:),
        "an absence" => SchoolRiderAbsence.where(school:, rid:),
        "a CCA booking" => CcaBooking.where(school_rider: @rider),
        "a bus request" => BusRequest.where(school_rider: @rider),
        "a bill" => SchoolBill.where(school_rider: @rider)
      }.select { |_, scope| scope.exists? }.keys
    end
  end
end
