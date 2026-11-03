# Confirm a Stop Service: the last day and a note to the parent. A last day before the notice allows stops the bus
# earlier, but fees still run to the end of the notice (pay_to). The child leaves the route plans after the last day.
module BusRequests
  class ConfirmStop < ApplicationService
    def initialize(req, last_on:, note:, user:)
      @req = req
      @last = last_on.presence && Date.parse(last_on.to_s)
      @note = note.to_s.strip
      @user = user
    end

    def call
      raise Error, "Only a stop request waiting for a decision can be confirmed" unless @req.kind == "stop" && @req.status == "Requested"
      raise Error, "Pick the last day" unless @last
      raise Error, "The last day cannot be in the past" if @last < Date.current

      pay_to = @req.earliest_on && @last < @req.earliest_on ? @req.earliest_on : @last
      ApplicationRecord.transaction do
        @req.update!(status: "Stopping", last_on: @last, confirmed_at: Time.current, confirmed_by: @user, confirm_note: @note.presence, pay_to:)
        @req.log!("Confirmed. Last day #{@last.strftime('%d/%m/%Y')}. Fees charged up to #{pay_to.strftime('%d/%m/%Y')}" \
                  "#{". Note to the parent: #{@note}" if @note.present?}", by: @user)
      end
      PlanSync.call(@req, user: @user)
      @req
    rescue Date::Error
      raise Error, "Pick the last day"
    end
  end
end
