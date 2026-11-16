# Convoy App › New Booking: what the form offers on a booking account. Who Pays: a school / company account offers the
# organisation (invoiced after the trip, its approval flow) and Pay Myself (prepaid, no approval, billed to the person's
# Individual client at that company); Personal offers Pay Myself only (Bill to My Company opens the add-work-email sheet,
# FE). Each payer has its vehicle types (the client's Bookable Vehicles; Pay Myself: every type the company offers).
# The organisation also brings its Bill To funds, its sites (a client with sites needs one, as in the Client Portal) and
# its default PO. Pay Myself brings the ways to pay (Finance Settings). Waiting time policy from the rate card.
# Inside `within`.
module ConvoyApp
  module Bookings
    class Form < ApplicationService
      def initialize(account:)
        @account = account
      end

      def call
        payers = []
        payers << client_payer if @account.link?
        payers << self_payer
        card = ::Bookings::Estimate.pricer_for(@account.link? ? @account.client : nil)&.card
        { account: @account.json, booker: Bookings.booker(@account), payers:, default_payer: payers.first[:key],
          receipt_allowed: @account.personal?, waiting: waiting(card),
          limits: { days: ::Booking::MAX_DAYS, span_days: ::Booking::MAX_SPAN_DAYS, trips_a_day: ::Booking::MAX_TRIPS_A_DAY,
                    vehicles_a_trip: BookingTrip::MAX_VEHICLES, stops: BookingTrip::MAX_STOPS, short_notice_days: SHORT_NOTICE_DAYS },
          kinds: BookingTrip::KIND_NAMES.map { |k, v| { key: k, label: v } }, disposal_hours: [ 3, 4, 5, 6, 8, 10, 12 ],
          contact_phone_format: "8 digits starting with 8 or 9" }
      end

      private

      def client_payer
        user = @account.client_user
        base = ::Portal::BookingForm.call(client_user: user)
        { key: "client", label: @account.client.name, sub: "Invoiced after the trip · approver signs off", prepaid: false,
          vehicle_types: base[:vehicle_types], funds: @account.client.bill_funds.map { { id: it.id, name: it.name } },
          fund_required: @account.client.bill_funds.any?, sites: base[:sites].map { it.slice(:id, :name) }, site_required: base[:site_required],
          default_po: @account.client.default_po, methods: [] }
      end

      def self_payer
        types = VehicleType.enabled_for(@account.company).order(:seats, :name).map { { id: it.id, name: it.name, seats: it.seats } }
        { key: "self", label: "Pay Myself", sub: @account.personal? ? "Card or PayNow" : "Pay now by card or PayNow · no approval", prepaid: true,
          vehicle_types: types, funds: [], fund_required: false, sites: [], site_required: false, default_po: nil,
          methods: Bookings.payment_options.map { it.json.merge(fee_text: it.fee_kind == "pct" ? "+#{it.fee.to_s('F').sub(/\.0\z/, '')}% card fee" : "No fee") },
          note: "#{'For trips the school does not fund. ' if @account.link?}You pay when you book. #{@account.tc} confirms the buses within 1 working day; if it can't, you are refunded in full." }
      end

      def waiting(card)
        return nil unless card

        text = "First #{card.wait_free_minutes} min free, then #{Bookings.money(card.wait_fee)} per #{card.wait_block_minutes} min per bus"
        { free_minutes: card.wait_free_minutes, fee: card.wait_fee, block_minutes: card.wait_block_minutes, text: }
      end
    end
  end
end
