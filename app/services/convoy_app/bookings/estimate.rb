# Convoy App › New Booking while it is filled in (nothing saved): each trip's estimate and its rate period ("Peak rate"),
# the total, and by payer — the organisation: who it is billed to and the approval it will get (the client's Approval
# Flow, read only, as Try a Booking: no approver to pick); Pay Myself: the card fee of the method and what is charged.
# Short notice when the first day is less than 3 days away. Inside `within`.
module ConvoyApp
  module Bookings
    class Estimate < ApplicationService
      def initialize(account:, payer:, params:, method: nil)
        @account = account
        @payer = Submit.payer!(account, payer)
        @params = params.to_h.deep_symbolize_keys
        @method = method
      end

      def call
        out = if @payer == "client"
          ::Portal::BookingEstimate.call(client_user: @account.client_user, params: @params)
        else
          self_estimate
        end
        dates = out[:trips].filter_map { it[:date] }
        out.merge(payer: @payer, short_notice: Bookings.short_notice?(dates.min), trips: out[:trips].zip(rates).map { |t, rate| t.merge(rate:) })
      end

      private

      def pricer
        @pricer ||= ::Bookings::Estimate.pricer_for(@payer == "client" ? @account.client : Bookings.individual_of(@account.app_account))
      end

      # [date, trip params] in the order the estimate lists them.
      def each_trip
        Array(@params[:days]).flat_map do |d|
          date = begin
            Date.iso8601(d[:date].to_s)
          rescue Date::Error
            nil
          end
          Array(d[:trips]).map { [ date, it ] }
        end
      end

      def self_estimate
        client = Bookings.individual_of(@account.app_account)
        trips = each_trip.map do |date, t|
          trip = ::Bookings::TripBuilder.call(BookingTrip.new, t.except(:standby, :return_standby))
          r = date && pricer ? ::Bookings::Estimate.call(client:, trip:, date:, pricer:) : nil
          { date:, kind: trip.kind, amount: r&.amount || 0, lines: r&.lines || [], without_rate: r&.without_rate }
        end
        total = trips.sum { it[:amount] }
        option = Bookings.payment_options.find { it.key == @method.to_s } || Bookings.payment_options.first
        fee = option ? option.fee_for(total) : 0.to_d
        { trips:, total:, rate_card: pricer&.card&.slice(:id, :name), method: option&.json, card_fee: fee, charged: total + fee,
          billed_to: { name: @account.app_account.display_name, own: false }, approval: nil }
      end

      # The rate period at each trip's pick-up ("Peak", "Weekend / PH"), for the "… rate" label.
      def rates
        each_trip.map do |date, t|
          minute = (Clock.minutes(t[:start_time].to_s) rescue nil) # rubocop:disable Style/RescueModifier
          date && minute && pricer ? pricer.period_for(date, minute)&.name : nil
        end
      end
    end
  end
end
