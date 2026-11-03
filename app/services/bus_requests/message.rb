# Message parents about their requests. Parent accounts are not live yet, so the message is logged on each request.
module BusRequests
  class Message < ApplicationService
    def initialize(reqs, text:, user:)
      @reqs = reqs
      @text = text.to_s.strip
      @user = user
    end

    def call
      raise Error, "Enter a message" if @text.blank?

      ApplicationRecord.transaction { @reqs.each { it.log!("Message sent: \"#{@text}\"", by: @user) } }
      @reqs
    end
  end
end
