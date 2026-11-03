# Waitlist or Decline requests (one or many): parents see only "we can't confirm a seat yet" for a waitlist; the reason
# is for the company. A decline's registration fee refund follows the Payment & Refund Policy.
module BusRequests
  class Decide < ApplicationService
    TO = { "Waitlisted" => WAITLIST_REASONS, "Declined" => DECLINE_REASONS }.freeze

    def initialize(reqs, to:, reason:, note:, user:)
      @reqs = reqs
      @to = to.to_s
      @reason = reason.to_s.strip
      @note = note.to_s.strip
      @user = user
    end

    def call
      raise Error, "Pick Waitlisted or Declined" unless TO.key?(@to)
      raise Error, "Pick a reason from the list" if @reason.present? && TO[@to].exclude?(@reason)

      bad = @reqs.reject { allowed?(it) }
      raise Error.new("#{bad.map(&:child_name).to_sentence} cannot be #{@to.downcase} now", details: { ids: bad.map(&:id) }) if bad.any?

      text = [ @to, @reason.presence, ("Note: #{@note}" if @note.present?) ].compact.join(". ")
      ApplicationRecord.transaction do
        @reqs.each do |req|
          req.update!(status: @to, reason: @reason.presence)
          req.log!(text, by: @user)
        end
      end
      @reqs
    end

    private

    def allowed?(req)
      return @to == "Declined" && %w[Requested Under\ Review].include?(req.status) if req.kind != "new"

      ACTIONABLE.include?(req.status) && req.status != @to
    end
  end
end
