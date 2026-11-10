# Accept new requests (one with a final quote and start date, or many at the Bus Fares quote), or Re-offer a lapsed one:
# Accepted with the confirm hours of the year's registration to pay, the seat held where Route Fit places the child,
# and the first invoice (the start's billing period at the final quote, due when the offer ends). A new child joins
# the rider list (Unpaid) and a family. Re-offer keeps the quote and the invoice number.
module BusRequests
  class Accept < ApplicationService
    ELIGIBLE = [ "Requested", "Under Review", "Waitlisted", "Lapsed" ].freeze

    def initialize(reqs, user:, reoffer: false, quote: nil)
      @reqs = reqs
      @user = user
      @reoffer = reoffer
      @quote = quote
    end

    def call
      list = @reqs.select { it.kind == "new" && (@reoffer ? it.live_status == "Lapsed" : ELIGIBLE.include?(it.live_status)) }
      raise Error, (@reoffer ? "Only a lapsed offer can be sent again" : "Nothing to accept in the selection") if list.empty?
      raise Error, "Accept one request at a time to change its fare or start" if @quote && list.size > 1

      check = Check.new(list.first.school)
      settings = FinanceSetting.current
      now = Time.current
      ApplicationRecord.transaction { list.each { accept(it, check, settings, now) } }
      list
    end

    private

    def accept(req, check, settings, now)
      base = Fare.base(req)
      start = quote_start(req, base)
      req.log!("Start date moved from #{fmt(req.start_on)} to #{fmt(start)}", by: @user, at: now) if start && start != req.start_on
      req.start_on = start if start
      unless @reoffer && req.quote_amount
        amount = @quote ? @quote[:amount].to_d : base[:amount].to_d
        raise Error, "#{req.child_name} has no fare from Bus Fares. Accept it on its own with a fare" unless amount.positive?

        req.assign_attributes(quote_amount: amount, quote_base: base[:amount], quote_unit: base[:unit], quote_note: @quote&.dig(:note).presence,
                              quoted_at: now, quoted_by: @user)
      end
      hours = req.academic_year&.registration&.confirm_hours || 48
      req.update!(status: "Accepted", offer_by: now + hours.hours, reason: nil, family: req.family || family_of_rider(req))
      req.places.delete_all
      check.places(req).each { req.places.create!(it) }
      bill = write_bill(req, settings, now)
      note = req.quote_note ? " (#{req.quote_note})" : ""
      req.log!("#{@reoffer ? 'Offer sent again' : 'Accepted'} at S$#{format('%.2f', req.quote_amount)} a #{req.quote_unit}#{note}. " \
               "First invoice #{bill.number} sent. Parent has #{hours} hours to pay", by: @user, at: now)
      Link.call(req, user: @user) unless req.renew || req.school_rider
    end

    # The start the admin picked (checked against what the family asked), and a note when the fare differs or the start is later.
    def quote_start(req, base)
      return unless @quote

      amount = @quote[:amount].to_s.gsub(/[^\d.]/, "").to_d
      raise Error, "Enter the monthly fare" unless amount.positive?

      start = @quote[:start_on].presence && Date.parse(@quote[:start_on].to_s)
      raise Error, "Pick the start date" unless start

      err = BusRequests.start_error(req, start)
      raise Error, err if err

      diff = amount != base[:amount].to_d
      late = BusRequests.start_late?(req, start)
      if (diff || late) && @quote[:note].to_s.strip.empty?
        why = diff && late ? "the fare differs and the start is later than asked" : diff ? "the fare differs from Bus Fares" : "the start is later than they asked"
        raise Error, "Add a note for the parent: #{why}"
      end
      @quote = @quote.merge(amount:, note: (diff || late) ? @quote[:note].to_s.strip : nil)
      start
    rescue Date::Error
      raise Error, "Pick the start date"
    end

    def write_bill(req, settings, now)
      bill = req.first_bill || req.build_first_bill(school: req.school, kind: "first", number: Finance::Numbering.next!("inv", settings:), created_by: @user,
                                                        issued_by: @user, issued_at: now)
      split = FinanceSetting.split(req.quote_amount, on: settings.gst_on?, rate: settings.gst_rate, mode: settings.gst_mode)
      period = Fare.first_period(req)
      bill.update!(academic_year: req.academic_year, family: req.family, school_rider: req.school_rider, status: "issued", bill_to: req.parent_name, bill_to_code: req.family&.code,
                   period_label: period[:label], period_starts_on: period[:starts_on], issued_on: now.to_date, due_at: req.offer_by, due_on: req.offer_by&.to_date,
                   subtotal: split[:sub], gst_rate: settings.gst_on? ? settings.gst_rate : 0, gst_amount: split[:gst], total: split[:total])
      write_line(bill, req, split[:sub])
      bill
    end

    # The one line of a first invoice: the child's first month.
    def write_line(bill, req, amount)
      line = bill.lines.first || bill.lines.build
      line.update!(rid: req.school_rider&.rid, child_name: req.child_name, description: "#{req.child_name} | First month, #{bill.period_label}", amount:)
    end

    # A renewing child is already in a family of the school.
    def family_of_rider(req)
      rider = req.school_rider or return
      FamilyRider.find_by(school: req.school, rid: rider.rid)&.family
    end

    def fmt(d) = d&.strftime("%d/%m/%Y")
  end
end
