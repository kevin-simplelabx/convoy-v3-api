# Convoy App › a booking: Accept Changes, Can't Accept (reply), Cancel (the options with the charge first, then send),
# Book Again (the copy to start New Booking from) and Track Buses.
module Api
  module V1
    module ConvoyApp
      class BookingActionsController < BookingBaseController
        # POST /app/bookings/:id/accept_changes → booking detail
        def accept_changes
          with_booking do |acc, b|
            ::ConvoyApp::Bookings::Changes.accept!(account: acc, booking: b)
            render json: { data: detail(acc, b) }
          end
        end

        # POST /app/bookings/:id/reply { reason, message } → booking detail
        def reply
          with_booking do |acc, b|
            ::ConvoyApp::Bookings::Changes.reply!(account: acc, booking: b, reason: params[:reason], message: params[:message])
            render json: { data: detail(acc, b) }
          end
        end

        # GET /app/bookings/:id/cancel → { scopes: [{ key, label, trip_ids, fee, fee_text, note, confirmed }], reasons }
        def cancel_options
          with_booking do |acc, b|
            runs = ::ConvoyApp::Bookings::Runs.load([ b ])
            scopes = ::ConvoyApp::Bookings::Cancel.scopes(b, runs).map do |s|
              { key: s.key, label: s.label, trip_ids: s.trips.map(&:id) }.merge(::ConvoyApp::Bookings::Cancel.quote(acc, b, s.trips, runs))
            end
            render json: { data: { scopes:, reasons: BookingCancelRequest::REASONS } }
          end
        end

        # POST /app/bookings/:id/cancel { scope: booking | day-<id> | trip-<id>, reason, note } → booking detail + outcome
        def cancel
          with_booking do |acc, b|
            out = ::ConvoyApp::Bookings::Cancel.call(account: acc, booking: b, scope: params.require(:scope), reason: params[:reason], note: params[:note])
            render json: { data: detail(acc, b), meta: { cancelled_trip_ids: out[:cancelled], request_id: out[:requested]&.id } }
          end
        end

        # GET /app/bookings/:id/copy?first_day=YYYY-MM-DD → days with new dates + the New Booking values
        def copy
          with_booking { |acc, b| render json: { data: ::ConvoyApp::Bookings::Copy.call(account: acc, booking: b, first_day: params[:first_day]) } }
        end

        # GET /app/bookings/:id/track → buses on the road today (404 when nothing runs now)
        def track
          with_booking do |acc, b|
            render json: { data: ::ConvoyApp::Bookings::Track.new(acc, b, ::ConvoyApp::Bookings::Runs.load([ b ])).call }
          end
        end
      end
    end
  end
end
