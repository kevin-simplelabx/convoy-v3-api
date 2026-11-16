# Convoy App › Bookings list card and booking detail (HTML bk.list, bd), from a booking loaded with INCLUDES and its runs
# (Runs). Buses: plates and drivers from the day before the trip (HTML "shared the day before"), the bus state on the day.
# Money: a prepaid booking shows what is paid less refunds (card fee included); a school / company booking the estimate,
# or the confirmed price (the runs' client price) once every trip left is confirmed, plus accepted cancellation charges.
# Inside `within`.
module ConvoyApp
  module Bookings
    class Present
      INCLUDES = [ :client, :bill_fund, :copied_from, :payments, :change_replies, :created_by_client_user, :created_by_app_account,
                   { cancel_requests: %i[booking_trip booking_day], days: { trips: [ :day, :points, :changes_made, { vehicles: :vehicle_type } ] },
                     trips: [ :day, :changes_made, { vehicles: :vehicle_type } ], approval: ::Portal::Approval::INCLUDES } ].freeze
      ICONS = { "one_way" => "arrow_forward", "two_way" => "sync_alt", "disposal" => "schedule", "airport" => "flight" }.freeze

      def initialize(account, booking, runs, now: Time.current)
        @account = account
        @b = booking
        @runs = runs
        @now = now
        @today = now.to_date
        @status = Status.booking(booking, runs, @today)
        @me = @b.paid_by_self?
      end

      attr_reader :status

      def card
        first = @b.days.first
        trip = first&.trips&.first
        { id: @b.id, number: @b.number, title: title, first_date: first&.date, days_count: @b.days.size, trips_count: @b.trips.size,
          buses_count: buses_count, pax: trip&.pax, start_time: trip&.start_time_hm, return_time: trip&.return_time_hm,
          status: @status, status_label: LABELS[@status], tone: TONES[@status], tab: Status.tab(@status) || "pending",
          payer: @b.payer, amount: amount, note: note, warm: warm? }
      end

      def detail
        card.merge(
          company: { name: @account.tc, ops_phone: @account.company.ops_phone }, account: @account.key,
          banner:, days: days, trips: @b.days.flat_map { |d| d.trips.map { trip_json(it) } },
          rows:, total: { label: total_label, amount: amount }, timeline:, actions:, short_notice: short_notice?,
          payments: @b.payments.map { it.slice(:kind, :method, :method_label, :amount, :card_fee, :reference, :paid_at, :note).merge(charged: it.charged) },
          cancel_parts: cancel_parts, replies: @b.change_replies.map { it.slice(:reason, :message, :replied_by_name, :created_at) },
          receipt: (@b.receipt_name && { name: @b.receipt_name, uen: @b.receipt_uen, address: @b.receipt_address })
        )
      end

      private

      def tc = @account.tc
      def title = @b.title || @b.number
      def open_trips = @b.trips.reject { it.cancelled? || it.rejected? }
      def buses_count = open_trips.sum(&:vehicles_count)
      def warm? = %w[pending changed cxreq].include?(@status)
      def confirmed? = %w[confirmed ongoing changed].include?(@status)
      def short_notice? = Bookings.short_notice?(@b.days.first&.date, @b.created_at.to_date)

      # The charge kept for cancelled parts: accepted requests (not a prepaid booking: its refunds already say it).
      def charges = @b.cancel_requests.select(&:accepted?).sum(&:fee_quoted)

      def amount
        return ::Bookings::Prepaid.net_charged(@b) if @me
        return charges if @status == "cancelled"

        prices = open_trips.map { |t| [ t, t.approved? ? @runs.price(t) : nil ] }
        (prices.sum { |t, p| p || t.estimate_amount } + charges).round(2)
      end

      def quoted? = !@me && open_trips.any? && open_trips.all?(&:approved?)

      def total_label
        return "Cancellation charge" if @status == "cancelled" && !@me
        return "Paid" if @me
        return "Estimated" unless quoted?

        @status == "completed" ? "Invoiced after the trip" : "Confirmed price"
      end

      def approver_names
        a = @b.approval
        return nil unless a && a.status != "none"

        view = ::Portal::ApprovalView.call(a)
        names = a.waiting? ? view[:waiting_for].pluck(:name) : view[:steps].flat_map { |s| s[:acts].select { it[:act] == "approve" }.map { it[:by][:name] } }
        names.uniq.to_sentence(two_words_connector: " or ", last_word_connector: " or ").presence
      end

      def replied?
        last = @b.change_replies.last or return false
        change = @b.trips.select(&:awaiting_ack?).flat_map(&:changes_made).map(&:created_at).max
        change.nil? || last.created_at >= change
      end

      def payment = @b.payments.find(&:payment?)

      def note
        case @status
        when "ongoing"
          live = @b.trips.find { it.date == @today && @runs.live?(it) }
          runs = live ? @runs.out(live) : []
          "Under way today · #{runs.count { here?(it) }} of #{runs.size} buses at the pick-up"
        when "changed" then replied? ? "You replied. #{tc} is sending another option" : "Changes from #{tc} waiting for your acceptance"
        when "pending"
          if @me && payment then "#{Bookings.money(payment.charged)} paid by #{payment.method_label} · #{tc} to confirm"
          elsif (names = approver_names) && @b.approval&.waiting? then "With #{names} for approval"
          else "Sent to #{tc} · waiting for confirmation"
          end
        when "approved" then "Approved · #{tc} to confirm"
        when "cxreq" then "Cancellation sent · #{tc} confirms it"
        else
          gone = @b.trips.count(&:cancelled?)
          past = %w[completed cancelled rejected].include?(@status)
          if gone.positive? && !past then "#{gone} #{'trip'.pluralize(gone)} cancelled"
          elsif @me && !past then "Paid personally"
          end
        end
      end

      def banner
        text, head, icon = case @status
        when "changed"
          items = @b.trips.select(&:awaiting_ack?).flat_map { |t| t.changes_made.last&.items.to_a.map { "#{t.date.strftime('%a %-d %b')}: #{it}" } }
          reply = @b.change_replies.last
          [ "#{tc} changed the booking. #{items.join('. ')}.#{" You replied: #{reply.reason.downcase}#{" (“#{reply.message}”)" if reply.message.present?}. #{tc} is sending another option." if replied?}",
            "Changes from #{tc}", "edit_note" ]
        when "pending", "approved"
          base = if @me && payment
            "#{Bookings.money(payment.charged)} paid by #{payment.method_label}. Refunded in full if #{tc} can't take the booking."
          elsif @b.approval&.waiting? then "Waiting for #{approver_names} to approve. #{tc} confirms the buses after that."
          else "Waiting for #{tc} to confirm the buses."
          end
          [ "#{base}#{" Short notice: #{tc} first checks it has buses and drivers free." if short_notice?}",
            @me || !@b.approval&.waiting? ? "Waiting for confirmation" : "Pending approval", "hourglass_top" ]
        when "cxreq"
          fee = @b.cancel_requests.select { it.open? }.sum(&:fee_quoted)
          [ "#{tc} confirms the cancellation and the charge (#{fee.positive? ? Bookings.money(fee) : 'none'}). The buses stay booked until then.",
            "Cancellation requested", "hourglass_top" ]
        when "cancelled"
          kept = @me ? ::Bookings::Prepaid.net_charged(@b) : charges
          text = if kept.positive? then "Cancellation charge #{Bookings.money(kept)}#{@me ? '; the rest is refunded.' : " on #{@b.client.name}'s invoice."}"
          elsif @me then "No charge. What you paid is refunded in full."
          else "No charge."
          end
          [ text, "Cancelled", "event_busy" ]
        when "completed"
          [ @me ? "Paid #{Bookings.money(amount)}. The receipt is in #{tc}'s name." : "#{tc} invoices #{@b.client.name} after the trip.", "Completed", "receipt_long" ]
        when "rejected"
          reason = @b.trips.filter_map(&:rejection_reason).first
          [ "#{tc} could not take this booking#{": #{reason}" if reason}.#{' What you paid is refunded in full.' if @me}", "Not taken", "event_busy" ]
        end
        return nil unless text

        { title: head, text:, icon:, tone: @status == "cancelled" || @status == "rejected" ? "danger" : (warm? ? "warning" : "neutral"),
          accept_changes: @status == "changed", reply: @status == "changed", reply_label: replied? ? "Reply Again" : "Can't Accept" }
      end

      def days
        @b.days.map { |d| { id: d.id, date: d.date, cancelled: d.trips.all?(&:cancelled?) } }
      end

      def trip_json(t)
        st = Status.trip(t, @b, @runs, @today)
        out = t.out_points
        { id: t.id, day_id: t.booking_day_id, date: t.date, kind: t.kind, kind_label: t.kind_name, icon: ICONS[t.kind],
          start_time: t.start_time_hm, return_time: t.return_time_hm, hours: t.hours, pax: t.pax, adults: t.adults,
          flight_number: t.flight_number, terminal: t.terminal, airport_direction: t.airport_direction,
          vehicles: t.vehicles.map { { vehicle_type_id: it.vehicle_type_id, name: it.vehicle_type.name, seats: it.vehicle_type.seats, count: it.count } },
          vehicles_text: t.vehicles.map { "#{it.count} × #{it.vehicle_type.name}" }.join(", "), note: t.note,
          contact: { name: t.contact_name, phone: t.contact_phone },
          status: st, status_label: Status::TRIP_LABELS[st], tone: Status::TRIP_TONES[st],
          points: out.each_with_index.map { |p, i| { name: p.name, address: p.address, lat: p.lat&.to_f, lng: p.lng&.to_f, note: p.note, time: (t.start_time_hm if i.zero?) } },
          back_points: (t.two_way? && t.own_way_back? ? t.back_points.map { { name: it.name, address: it.address, note: it.note } } : nil),
          return_text: t.two_way? ? "Return leaves #{out.last&.name} at #{t.return_time_hm}" : nil,
          estimate: t.estimate_amount, buses: buses(t, st), no_bus_text: no_bus_text(t, st), track: st == "live" }
      end

      def shown_buses?(t) = t.approved? && t.date <= @today + 1

      def buses(t, st)
        return [] unless shown_buses?(t)

        runs = @runs.out(t)
        runs.map.with_index(1) do |o, n|
          info = o.decorate.driver_info
          { n:, occurrence_id: o.id, plate: o.vehicle&.plate, desc: o.vehicle && [ [ o.vehicle.make, o.vehicle.model ].compact.join(" ").presence, ("#{o.vehicle.seats} seats" if o.vehicle.seats) ].compact.join(" · "),
            driver: info && { name: info[:name], photo: info[:photo] } }.merge(%w[done cancelled].include?(st) ? { state: nil, state_text: nil } : Track.state(o, @now))
        end
      end

      def no_bus_text(t, st)
        return nil if %w[done cancelled declined].include?(st) || (shown_buses?(t) && @runs.out(t).any?(&:vehicle_id))
        return "Buses are assigned once #{'approved and ' unless @me || @b.approval.nil?}confirmed." unless t.approved?

        "#{tc} shares the plates and drivers the day before."
      end

      def rows
        booker = @b.created_by_client_user&.name || @b.created_by_name || @b.coordinator_name
        first = @b.trips.min_by { [ it.date, it.start_time ] }
        list = [ { key: "requested_by", label: "Requested by", value: @me ? "#{booker} · personal" : booker },
                 { key: "contact", label: "Contact on the day", value: [ first&.contact_name, first&.contact_phone ].compact_blank.join(" · ").presence || booker } ]
        if @me
          list << { key: "payment", label: "Payment", value: payment ? "#{Bookings.money(payment.charged)} paid by #{payment.method_label}" : nil }
        else
          list << { key: "approver", label: "Approver", value: approver_names || "No approval needed" }
          list << { key: "bill_to", label: "Bill to", value: @b.bill_fund ? "#{@b.client.name} · #{@b.bill_fund.name}" : @b.client.bill_name }
          list << { key: "payment", label: "Payment", value: "Invoiced after the trip" }
        end
        list << { key: "po", label: "PO", value: @b.po_number } if @b.po_number.present?
        list << { key: "copied_from", label: "Copied from", value: @b.copied_from.number } if @b.copied_from
        list << { key: "vehicles", label: "Vehicles", value: buses_count.to_s }
        cancel_parts.each { list << { key: "cancel", label: it[:status] == "accepted" ? "Cancelled" : "Cancel requested", value: "#{it[:label]} · #{it[:fee].positive? ? "#{Bookings.money(it[:fee])} charge" : 'no charge'}" } }
        list << { key: "receipt", label: "Receipt For", value: [ @b.receipt_name, (@b.receipt_uen && "UEN #{@b.receipt_uen}"), @b.receipt_address ].compact.join(" · ") } if @b.receipt_name
        list << { key: "notes", label: "Notes", value: @b.notes } if @b.notes.present?
        list
      end

      def cancel_parts
        @b.cancel_requests.reject(&:declined?).map do |r|
          label = if r.for_trip? then "#{r.booking_trip.kind_name} · #{r.booking_trip.date.strftime('%a %-d %b')}"
          elsif r.for_day? then r.booking_day.date.strftime("%a %-d %b")
          else "Whole Booking"
          end
          { id: r.id, scope: r.scope, label:, status: r.status, fee: r.fee_quoted, reason: r.reason, requested_at: r.requested_at }
        end
      end

      # HTML timeline stages: Personal (Requested, Paid, Provider confirmation, On the day, Receipt); credit (Requested,
      # School approval, Provider confirmation, On the day, Invoiced). state done | current | todo.
      def timeline
        conf = confirmed? || @status == "cxreq"
        stage = if @status == "completed" then 4
        elsif conf then 3
        elsif @me then 2
        else @status == "approved" ? 2 : 1
        end
        sent = "Sent #{@b.created_at.strftime('%a %-d %b')} by #{@me ? 'you' : (@b.created_by_client_user&.name || @b.coordinator_name)}"
        day = "Plates and drivers shared the day before · live tracking"
        names = [ "Requested", @me ? "Paid" : "School approval", "Provider confirmation", "On the day", @me ? "Receipt" : "Invoiced" ]
        metas = [ sent,
                  @me ? (payment ? "#{Bookings.money(payment.charged)} by #{payment.method_label}" : "When you book") : approval_meta(stage),
                  "#{tc}#{stage > 2 ? ' confirmed the buses' : ' confirms within 1 working day'}", day,
                  @me ? "In #{tc}'s name after the trip" : "After the trip, to the school's finance office" ]
        names.each_with_index.map { |n, i| { name: n, meta: metas[i], state: i < stage ? "done" : (i == stage ? "current" : "todo") } }
      end

      def approval_meta(stage)
        names = approver_names or return "No approval needed"

        "#{names}#{stage > 1 ? ' approved' : ' to approve'}"
      end

      def actions
        scopes = Cancel.scopes(@b, @runs, now: @now)
        can_cancel = scopes.any? && %w[completed cancelled rejected cxreq].exclude?(@status)
        live = @b.trips.any? { it.date == @today && @runs.live?(it) }
        { cancel: can_cancel, cancel_label: can_cancel ? (@b.trips.any?(&:approved?) ? "Request Cancellation" : "Cancel Booking") : nil,
          book_again: true, call_ops: live, track: live }
      end

      def here?(o) = Track.state(o, @now)[:state] == "here"
    end
  end
end
