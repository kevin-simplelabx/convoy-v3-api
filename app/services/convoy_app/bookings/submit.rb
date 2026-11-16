# Convoy App › New Booking › Send for Approval / Pay. Needs the charter terms agreed and the contact on the day (the booker,
# or a name and an SG mobile; written on every trip as the trip contact).
#   payer client (a school / company account): Portal::SubmitBooking as the client user (the client's rules, Bill To
#     fund when the client has funds, its approval flow decides; no flow = straight to the company), source "app".
#   payer self (Personal, or Pay Myself on a school account): a booking of the person's Individual client at the account's
#     company (made on the first booking), the self-service rules of Bookings::Save, no approval (straight to the company),
#     paid at once with the method picked (simulated: estimate + card fee). Personal may ask for the receipt in a
#     company's name (name, UEN, billing address).
# Book Again sends copied_from_id (a booking of the same account). Inside `within`.
module ConvoyApp
  module Bookings
    class Submit < ApplicationService
      PHONE = /\A[89]\d{7}\z/

      def self.payer!(account, payer)
        payer = payer.presence || (account.personal? ? "self" : "client")
        raise Error, "Pick who pays" unless %w[client self].include?(payer)
        raise Error, "Personal bookings are paid by you" if payer == "client" && account.personal?

        payer
      end

      def initialize(account:, params:)
        @account = account
        @params = params.to_h.deep_symbolize_keys
        @payer = self.class.payer!(account, @params[:payer])
        @booking = (@params[:booking] || {}).to_h.deep_symbolize_keys
      end

      # true when the submit_token was sent before: the booking returned is the one made then (nothing new, nothing charged).
      attr_reader :repeated

      def call
        if (found = sent_before)
          @repeated = true
          return found
        end
        raise Error.new("Agree to the charter terms to continue", code: "terms") unless ActiveModel::Type::Boolean.new.cast(@params[:agree])

        contact = contact!
        days = Array(@booking[:days]).map { |d| d.merge(trips: Array(d[:trips]).map { it.merge(contact_name: contact[:name], contact_phone: contact[:phone]) }) }
        fields = @booking.slice(:title, :notes).merge(days:)
        @payer == "client" ? for_client(fields) : for_self(fields)
      rescue ActiveRecord::RecordNotUnique => e
        # The same form sent twice at once: the other request made it.
        raise unless e.message.include?("submit_token") && (found = sent_before)

        @repeated = true
        found
      end

      private

      def booker = @booker ||= Bookings.booker(@account)

      def contact!
        c = @params[:contact] || {}
        return { name: booker[:name], phone: booker[:phone] } if c.blank? || ActiveModel::Type::Boolean.new.cast(c[:me])

        digits = c[:phone].to_s.gsub(/\D/, "").delete_prefix("65")
        raise Error, "Enter the contact name and an 8-digit mobile number" if c[:name].to_s.squish.blank? || !digits.match?(PHONE)

        { name: c[:name].to_s.squish, phone: "+65 #{digits[0, 4]} #{digits[4, 4]}" }
      end

      def copied_from
        id = @params[:copied_from_id].presence or return nil
        Bookings.visible(@account).find(id).id
      end

      def common = { terms_accepted_at: Time.current, copied_from_booking_id: copied_from, submit_token: }

      # The form's token (any string the app makes once per New Booking form, a UUID); optional.
      def submit_token = @params[:submit_token].to_s.strip.first(64).presence

      # The booking this person already made with this token (as the booker in the app, or as the link's client user).
      def sent_before
        token = submit_token or return
        mine = ::Booking.where(created_by_app_account_id: @account.app_account.id)
        mine = mine.or(::Booking.where(created_by_client_user_id: @account.client_user.id)) if @account.link?
        mine.find_by(submit_token: token)
      end

      def for_client(fields)
        client = @account.client
        fund = @booking[:client_bill_fund_id].presence
        raise Error, "Pick the fund to bill" if fund.nil? && client.bill_funds.any?

        params = fields.merge(@booking.slice(:client_site_id, :po_number), client_bill_fund_id: fund,
                              coordinator_name: booker[:name], coordinator_email: booker[:email], coordinator_phone: booker[:phone],
                              coordinator_org: client.name)
        ::Portal::SubmitBooking.call(client_user: @account.client_user, params:, source: "app", attributes: common)
      end

      def for_self(fields)
        option = Bookings.payment_options.find { it.key == @params[:method].to_s } or raise Error, "Pick how to pay"
        ::Booking.transaction do
          client = Bookings.individual!(@account)
          booking = client.bookings.new(company_id: client.company_id, payer: "self", booked_via_client_user_id: @account.client_user&.id, **common, **receipt)
          params = fields.merge(client_id: client.id, coordinator_name: booker[:name], coordinator_email: booker[:email], coordinator_phone: booker[:phone])
          booking = ::Bookings::Save.call(booking:, params:, actor: @account.app_account)
          priced!(booking)
          payment = ::Bookings::Prepaid.pay!(booking:, option:)
          ::Bookings::Notify.call(booking:, kind: "new_booking", actor_name: booker[:name],
                                  message: "New booking from #{booker[:name]} (personal) in the Convoy App, #{Bookings.money(payment.charged)} paid by #{option.label}")
          booking
        end
      end

      # Paid at once on the estimate: every vehicle must have a price (else it would be charged S$0 and never invoiced).
      def priced!(booking)
        pricer = ::Bookings::Estimate.pricer_for(booking.client)
        booking.trips.each do |t|
          r = ::Bookings::Estimate.call(client: booking.client, trip: t, date: t.date, pricer:)
          next if r.without_rate.zero? && r.amount.positive?

          name = r.unpriced.first || "this trip"
          raise Error.new("We can't price #{name.start_with?('this') ? name : "a #{name}"} online. Call #{@account.tc} or pick another vehicle",
                          code: "no_price")
        end
      end

      # Receipt in My Company's Name (Personal only): company name and billing address, UEN optional.
      def receipt
        r = @params[:receipt]
        return {} if r.blank? || !@account.personal?
        raise Error, "Enter the company name and billing address for the receipt" if r[:name].to_s.squish.blank? || r[:address].to_s.strip.blank?

        { receipt_name: r[:name].to_s.squish, receipt_uen: r[:uen].presence, receipt_address: r[:address].to_s.strip }
      end
    end
  end
end
