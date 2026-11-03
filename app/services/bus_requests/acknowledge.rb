# Acknowledge a mid-year request: Under Review with the answer date and an optional note, both shown to the parent.
module BusRequests
  class Acknowledge < ApplicationService
    def initialize(req, answer_by:, note:, user:)
      @req = req
      @answer_by = answer_by.presence && Date.parse(answer_by.to_s)
      @note = note.to_s.strip
      @user = user
    end

    def call
      set = BusRequests.mid_settings(@req.academic_year)
      raise Error, "Only a mid-year request waiting to be acknowledged can be acknowledged" unless @req.status == "Requested" && BusRequests.mid?(@req, set)
      raise Error, "Pick the answer date" unless @answer_by
      raise Error, "The answer date cannot be in the past" if @answer_by < Date.current

      ApplicationRecord.transaction do
        @req.update!(status: "Under Review", acked_at: Time.current, acked_by: @user, answer_by: @answer_by, ack_note: @note.presence,
                     ack_plan_weeks: set.plan_weeks)
        @req.log!("Acknowledged. Answer expected by #{@answer_by.strftime('%d/%m/%Y')}#{". Note to the parent: #{@note}" if @note.present?}", by: @user)
      end
      @req
    rescue Date::Error
      raise Error, "Pick the answer date"
    end
  end
end
