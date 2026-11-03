# Confirm a Change of Address (the new pick-up point and the fare from the move date) or a Change of Service (the fare
# after it). A higher fare waits for the parent to agree in the Convoy App; otherwise it is Active and goes into the
# route plans from its date. From Not Agreed this is Change the Fare.
module BusRequests
  class ConfirmChange < ApplicationService
    def initialize(req, amount:, note:, user:, stop: nil)
      @req = req
      @amount = amount.to_s.gsub(/[^\d.]/, "").to_d
      @note = note.to_s.strip
      @stop = stop.to_s.strip
      @user = user
    end

    def call
      raise Error, "Only a change of address or service is confirmed here" unless %w[adr svc].include?(@req.kind)
      raise Error, "This request is not waiting for a decision" unless OPEN.include?(@req.live_status)
      raise Error, @req.kind == "adr" ? "Enter the new monthly fare" : "Enter the monthly fare" unless @amount.positive?
      raise Error, "Enter the new pick-up point" if @req.kind == "adr" && @stop.empty?

      up = @amount > @req.current_fare.to_d
      when_txt = "from #{@req.effective_on&.strftime('%d/%m/%Y')}"
      text = if @req.kind == "adr"
               "New pick-up #{@stop}, S$#{format('%.2f', @amount)} a month #{when_txt}#{up ? '. Waiting for the parent to agree' : '. Applies from the move date'}"
      else
               "#{BusRequest.service_text(@req.am, @req.pm, @req.cca)} #{when_txt} at S$#{format('%.2f', @amount)} a month" \
                 "#{up ? '. Waiting for the parent to agree' : '. Applies from that date'}#{". Note to the parent: #{@note}" if @note.present?}"
      end
      ApplicationRecord.transaction do
        @req.update!(quote_amount: @amount, quote_base: Fare.base(@req)[:amount], quote_unit: "month", quote_note: @note.presence, quoted_at: Time.current,
                     quoted_by: @user, new_stop: @req.kind == "adr" ? @stop : @req.new_stop, status: up ? "Accepted" : "Active", agree: up ? "wait" : nil,
                     reason: nil)
        @req.log!(text, by: @user)
      end
      PlanSync.call(@req, user: @user) unless up
      @req
    end
  end
end
