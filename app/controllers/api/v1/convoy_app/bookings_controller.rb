# Convoy App › Bookings: the booking accounts (Personal + school / company links), the list (Current / Pending / Past /
# All), a booking's details, and New Booking (its form, the live estimate with the approval preview or the card fee, and
# Send for Approval / Pay).
module Api
  module V1
    module ConvoyApp
      class BookingsController < BookingBaseController
        # GET /app/bookings/accounts → { accounts: [account], work_hint }  (work_hint: no school / company link yet)
        def accounts
          list = ::ConvoyApp::Bookings.accounts(current_account)
          render json: { data: { accounts: list.map(&:json), work_hint: list.none?(&:link?) } }
        end

        # GET /app/bookings?account=&tab=current|pending|past|all&page= → { data: [card], meta, account }
        def index
          out = within { ::ConvoyApp::Bookings::List.call(account:, tab: params[:tab], page: params[:page]) }
          render json: { data: out[:data], meta: out[:meta].merge(tab: out[:tab], account: out[:account]) }
        end

        # GET /app/bookings/:id → booking detail
        def show
          with_booking { |acc, b| render json: { data: detail(acc, b) } }
        end

        # GET /app/bookings/form?account=
        def form
          render json: { data: within { ::ConvoyApp::Bookings::Form.call(account:) } }
        end

        # POST /app/bookings/estimate { account, payer, method, booking: { days: [...] } } — nothing saved.
        def estimate
          data = within { ::ConvoyApp::Bookings::Estimate.call(account:, payer: params[:payer], method: params[:method], params: booking_params) }
          render json: { data: }
        end

        # POST /app/bookings { account, payer: client|self, method (self), booking: {...}, contact: { me } | { name, phone },
        #   receipt: { name, uen, address } (Personal), agree: true, copied_from_id, submit_token (one per form) }
        #   → booking detail (201; 200 with the booking already made when the same submit_token comes again)
        def create
          body = params.permit(:payer, :method, :agree, :copied_from_id, :submit_token, contact: %i[me name phone], receipt: %i[name uen address]).to_h
          repeated = false
          data = within do
            submit = ::ConvoyApp::Bookings::Submit.new(account:, params: body.merge(booking: booking_params.to_h))
            booking = submit.call
            repeated = submit.repeated
            detail(account, booking)
          end
          render json: { data: }, status: repeated ? :ok : :created
        end
      end
    end
  end
end
