# The parent did not agree to the higher fare after a move: keep the old pick-up and fare (the move is not applied), or
# stop the service from the move date (the child leaves the route plans then). Changing the fare is ConfirmChange.
module BusRequests
  class NotAgreed < ApplicationService
    def initialize(req, choice:, user:)
      @req = req
      @choice = choice.to_s
      @user = user
    end

    def call
      raise Error, "Only a change of address the parent did not agree to is decided here" unless @req.kind == "adr" && @req.status == "Not Agreed"

      case @choice
      when "keep"
        @req.update!(status: "Declined", reason: "Kept the old pick-up")
        @req.log!("Kept the old pick-up and fare. The move is not applied", by: @user)
      when "stop"
        @req.update!(status: "Stopped", reason: "Service stops from the move date")
        @req.log!("Service stops from #{@req.effective_on&.strftime('%d/%m/%Y')}", by: @user)
        PlanSync.call(@req, user: @user)
      else raise Error, "Pick keep or stop"
      end
      @req
    end
  end
end
