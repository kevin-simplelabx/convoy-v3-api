# Client Portal › New Booking › Submit: saves the booking (Bookings::Save with the client user: portal rules), then
# works out the approval it needs (Portal::ApprovalRoute: the booking's site, the booker, its trip types, the estimate,
# days ahead) and keeps it on the booking (Portal::Approval.start!). Needs approval: the trips wait for it
# (awaiting_client). Else they go to the transport company (pending) and its coordinators are told (bell: New booking).
# Files: up to 5 MB each.
module Portal
  class SubmitBooking < ApplicationService
    MAX_FILE = 5.megabytes

    def initialize(client_user:, params:, files: [])
      @user = client_user
      @client = client_user.client
      @params = params.to_h.deep_symbolize_keys
      @files = Array(files).compact_blank
    end

    def call
      check_files
      Booking.transaction do
        booking = Bookings::Save.call(booking: @client.bookings.new(company_id: @client.company_id),
                                      params: @params.merge(client_id: @client.id), actor: @user)
        @files.each { booking.attachments.new(file: it).stamp_actor(:uploaded, @user).save! }
        route = ApprovalRoute.call(client: @client, booking: self.class.route_input(booking, @user))
        Approval.start!(booking:, route:)
        route.need ? wait_for_approval(booking) : send_on(booking)
        booking
      end
    end

    # What the approval rules look at.
    def self.route_input(booking, booker)
      trips = booking.trips.includes(:day).to_a
      { site_id: booking.client_site_id, booker:, kinds: trips.map(&:kind).uniq, amount: booking.estimate_amount,
        lead: (trips.map(&:date).min - Date.current).to_i }
    end

    private

    def check_files
      raise Error, "Up to #{Booking::MAX_ATTACHMENTS} files per booking" if @files.size > Booking::MAX_ATTACHMENTS
      big = @files.find { it.size > MAX_FILE }
      raise Error, "#{big.original_filename} is over 5 MB" if big
    end

    def wait_for_approval(booking)
      booking.trips.reload.each { it.update!(status: "awaiting_client") }
    end

    def send_on(booking)
      Bookings::Notify.call(booking:, kind: "new_booking", actor_name: @user.name,
                            message: "New booking from #{@user.name} (#{@client.name}) in the Client Portal")
    end
  end
end
