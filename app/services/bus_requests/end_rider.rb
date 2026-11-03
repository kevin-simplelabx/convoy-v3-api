# End Rider / Remove from Rider List: the child is off the rider list (and the routes) from the day after the end the
# request works out; noted on the request. One click for the company — the rider list never changes by itself.
module BusRequests
  class EndRider < ApplicationService
    def initialize(req, user:)
      @req = req
      @user = user
    end

    def call
      e = BusRequests.end_of(@req) or raise Error, "This request has no rider to end"
      rider = @req.school_rider
      ApplicationRecord.transaction do
        rider.update!(ends_on: e[:end])
        @req.update!(ended_on: e[:end], ended_at: Time.current, ended_by: @user)
        @req.log!("Rider #{rider.rid} ended #{e[:end].strftime('%d/%m/%Y')}. Off the rider list from the next day", by: @user)
      end
      @req
    end
  end
end
