# The parent's reply to a higher fare after a move or a change of service (the Convoy App): Active (and into the route
# plans from its date), or Not Agreed for the company to decide.
module BusRequests
  class Agree < ApplicationService
    def initialize(req, yes:)
      @req = req
      @yes = yes
    end

    def call
      raise Error, "This request is not waiting for the parent" unless @req.waiting_for_parent?

      @req.update!(agree: @yes ? "yes" : "no", status: @yes ? "Active" : "Not Agreed")
      @req.log!(@yes ? "Parent agreed to the new fare" : "Parent did not agree to the new fare", by: "Parent")
      PlanSync.call(@req) if @yes
      @req
    end
  end
end
