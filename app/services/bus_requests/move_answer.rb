# Move a mid-year request's answer date with a reason the parent sees; every move is kept.
module BusRequests
  class MoveAnswer < ApplicationService
    def initialize(req, answer_by:, reason:, user:)
      @req = req
      @answer_by = answer_by.presence && Date.parse(answer_by.to_s)
      @reason = reason.to_s.strip
      @user = user
    end

    def call
      set = BusRequests.mid_settings(@req.academic_year)
      raise Error, "Only a mid-year request under review has an answer date to move" unless @req.status == "Under Review" && BusRequests.mid?(@req, set)
      raise Error, "Pick the new date" unless @answer_by
      raise Error, "Pick a different date" if @answer_by == current
      raise Error, "The new date cannot be in the past" if @answer_by < Date.current
      raise Error, "Add the reason. The parent sees it" if @reason.blank?

      ApplicationRecord.transaction do
        @req.answer_moves.create!(from_date: current, to_date: @answer_by, reason: @reason, moved_at: Time.current, moved_by: @user)
        @req.update!(answer_by: @answer_by, acked_at: @req.acked_at || Time.current, acked_by: @req.acked_by || @user)
        @req.log!("Answer date moved to #{@answer_by.strftime('%d/%m/%Y')}. Reason: #{@reason}", by: @user)
      end
      @req
    rescue Date::Error
      raise Error, "Pick the new date"
    end

    private

    def current
      @current ||= @req.answer_by || BusRequests.clock(@req, BusRequests.mid_settings(@req.academic_year), Date.current, BusRequests::Days.new)&.dig(:by)
    end
  end
end
