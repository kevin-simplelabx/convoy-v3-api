# A bus request as the parent sees it (Application Status, the Renew / Change Service / Stop lists and the Change of
# Address banner): the badge (HTML depStatus), the 4-step timeline, the rows, the status line in the app's words, and
# what the parent may do. Internal reasons stay with the company: a waitlist reads "can't confirm a seat yet". Bills
# (registration fee, first invoice) are shown to the Billing Contact only. Call inside the request's company.
module ConvoyApp
  module Parents
    module Present
      SERVICE = { "both" => "Two Ways · To School and Home", "am" => "One Way · Morning", "pm" => "One Way · Afternoon" }.freeze
      SHORT = { "both" => "Two Ways", "am" => "Morning Only", "pm" => "Afternoon Only" }.freeze
      BADGE = { "Active" => %w[Active success], "Accepted" => %w[Accepted success], "Lapsed" => [ "Offer Lapsed", "neutral" ],
                "Waitlisted" => %w[Waitlisted warning], "Declined" => %w[Declined danger], "Withdrawn" => %w[Withdrawn neutral],
                "Under Review" => [ "Under Review", "info" ], "Requested" => %w[Requested info] }.freeze

      module_function

      def service(req) = req.am && req.pm ? "both" : req.am ? "am" : "pm"
      def money(x) = format("S$%.2f", x.to_d)
      def long(d) = Parents.long(d)

      # The badge of a new request: Fee Unpaid while the registration fee is owed, else the status (HTML depStatus).
      def badge(req, now = Time.current)
        st = req.live_status(now)
        return { label: "Agree to New Fare", tone: "warning" } if req.waiting_for_parent?
        return { label: "Fee Unpaid", tone: "warning" } if %w[Requested Under\ Review].include?(st) && !req.fee_paid

        label, tone = BADGE[st] || [ st, BusRequest::TONES[st] || "neutral" ]
        { label:, tone: }
      end

      def call(req, billing:, now: Time.current)
        st = req.live_status(now)
        tc = req.school.company.name
        quote = req.quote_amount
        base = {
          id: req.id, code: req.code, kind: req.kind, renew: req.renew, status: st, badge: badge(req, now), submitted_at: req.submitted_at,
          school: { id: req.school_id, name: req.school.name }, company: Parents.company_json(req.school.company), year: req.academic_year&.key,
          child: { dependant_id: req.dependant_id, name: req.child_name, first_name: req.child_name.to_s.split.first },
          level: req.level, student_id: req.student_no, service: service(req), service_text: SERVICE[service(req)], cca: req.cca, cca_from: req.cca_from,
          start: { when: req.start_when, on: req.start_on, text: start_text(req) },
          pickup: (req.am ? { address: req.address, postal: req.postal } : nil),
          dropoff: (req.pm ? (req.dropoff_address ? { address: req.dropoff_address, postal: req.dropoff_postal } : { address: req.address, postal: req.postal }) : nil),
          fare: { estimate: req.estimate, km: req.km, quote:, unit: req.quote_unit || "month", note: req.quote_note && "#{tc}: #{req.quote_note}",
                  current: req.current_fare },
          offer: (st == "Accepted" && req.kind == "new" && req.offer_by ? { by: req.offer_by, hours_left: [ ((req.offer_by - now) / 3600).ceil, 0 ].max } : nil),
          message: message(req, st, tc), line: line(req, st, tc), timeline: (timeline(req, st, tc) if req.kind == "new"),
          change: (change(req) unless req.kind == "new"),
          can: { withdraw: req.kind == "new" && %w[Requested Under\ Review Accepted Waitlisted Lapsed].include?(st),
                 agree: req.waiting_for_parent?, pay_first_invoice: billing && pay_first?(req, st), pay_registration: billing && !req.fee_paid && req.registration_bill_id.present? }
        }
        base[:registration_fee] = registration(req, billing)
        base[:first_invoice] = billing ? first_invoice(req) : nil
        base
      end

      # The start as the family asked (requests.js startTxt, app dates), or the company's date once quoted.
      def start_text(req)
        d = long(req.start_on)
        return "From #{d}" if req.quote_amount || req.start_when.nil?

        why = req.fixed_why
        case req.start_when
        when "asap" then "As soon as possible"
        when "first" then "From the first school day, #{d}"
        when "fixed" then "From #{d}, not earlier#{" (#{why})" if why.present?}"
        else "From #{d}, earlier is fine"
        end
      end

      def pay_first?(req, st) = st == "Accepted" && req.kind == "new" && req.first_bill.present? && !req.first_bill.paid?

      # Registration Fee row: paid / unpaid to every adult; the amount and bill only to the Billing Contact.
      def registration(req, billing)
        bill = req.registration_bill
        return unless bill

        line = bill.lines.find { it.child_name == req.child_name }
        { paid: req.fee_paid, amount: billing ? line&.amount : nil, bill: billing ? bill_json(bill) : nil }
      end

      def first_invoice(req)
        bill = req.first_bill
        bill && bill.issued? ? bill_json(bill) : nil
      end

      def bill_json(bill)
        { id: bill.id, number: bill.number, period: bill.period_label, total: bill.total, due_on: bill.due_on, due_at: bill.due_at, paid: bill.paid? }
      end

      # The card under the badge (waitlist, decline, lapse, a mid-year acknowledgement).
      def message(req, st, tc)
        first = req.child_name.to_s.split.first
        case st
        when "Waitlisted" then { title: "On the waitlist", text: "#{tc} can't confirm a seat yet. You'll hear from them when one opens." }
        when "Declined" then { title: "Request declined", text: "#{tc} cannot offer a seat for #{first}." }
        when "Lapsed" then { title: "Offer lapsed", text: "The first invoice was not paid in time. Ask #{tc} to offer the seat again." }
        when "Under Review" then ack_message(req, tc)
        end
      end

      def ack_message(req, tc)
        return unless req.acked_at && req.answer_by

        move = req.answer_moves.last
        dot = ->(x) { x.to_s.strip.sub(/\.?\z/, ".") }
        text = move ? "Moved from #{long(move.from_date)}. #{dot.(move.reason)}" : "Received. Changes to bus routes can take about #{req.ack_plan_weeks || 3} weeks, as buses may need to be swapped or resized."
        text += " #{tc}: #{dot.(req.ack_note)}" if req.ack_note.present?
        { title: "Answer expected by #{long(req.answer_by)}", text: }
      end

      # Requested -> Under Review -> Accepted -> Active, with the HTML's notes.
      def timeline(req, st, tc)
        stage = st == "Active" ? 3 : st == "Accepted" ? 2 : 1
        fee = req.registration_bill_id ? (req.fee_paid ? " · registration fee paid" : " · registration fee unpaid") : ""
        review = if req.acked_at && st == "Under Review" then "Acknowledged #{long(req.acked_at.to_date)} · answer by #{long(req.answer_by)}"
        elsif req.mid && st == "Requested" then "Waiting for #{tc} to acknowledge · within #{req.academic_year&.registration&.ack_days || 3} working days"
        elsif st == "Under Review" then "#{tc} is checking the route and seats"
        else "Waiting for #{tc} to open it · usually 1 to 2 weeks"
        end
        starts = req.start_when == "asap" && !req.quote_amount ? "Service starts as soon as there is a seat" : "Service starts #{long(req.start_on)}"
        [ [ "Requested", "Submitted #{long(req.submitted_at.to_date)}#{fee}" ], [ "Under Review", review ],
          [ "Accepted", "Final quote and first invoice issued · pay to confirm" ], [ "Active", "#{starts} · pick-up point and bus shared before then" ] ]
          .each_with_index.map { |(name, meta), i| { name:, meta:, state: i < stage ? "done" : i == stage ? "current" : "todo" } }
      end

      # The status line of the Renew / Change Service / Stop lists and the address banner (HTML sreq `line`, hm.addrTxt).
      def line(req, st, tc)
        q = req.quote_amount
        if req.waiting_for_parent?
          return "#{tc} confirmed the change. The fare goes from #{money(req.current_fare)} to #{money(q)} a month#{" (#{req.quote_note})" if req.quote_note}. Agree to apply it."
        end

        case st
        when "Accepted" then "Accepted at #{money(q || req.estimate)} a month#{" (#{tc}: #{req.quote_note})" if req.quote_note}. Pay the first invoice to keep the seat."
        when "Under Review" then req.acked_at ? "Answer expected by #{long(req.answer_by)}#{". #{tc}: #{req.ack_note}" if req.ack_note.present?}" : "#{tc} is looking at it"
        when "Stopping" then "Confirmed. The last day is #{long(req.last_on)}#{". #{tc}: #{req.confirm_note}" if req.confirm_note.present?}"
        when "Stopped" then req.kind == "adr" ? "#{tc} stops the service from the move date" : "The bus service ended on #{long(req.last_on)}"
        when "Active" then active_line(req, q)
        when "Not Agreed" then "You did not agree to the new fare. #{tc} will contact you"
        when "Declined" then req.kind == "adr" ? "#{tc} kept the old pick-up" : "#{tc} could not make this change"
        when "Lapsed" then "The first invoice was not paid in time"
        when "Waitlisted" then "#{tc} can't confirm a seat yet"
        when "Withdrawn" then "Withdrawn"
        else "Sent to #{tc} on #{long(req.submitted_at.to_date)}#{". #{tc} acknowledges it within #{req.academic_year&.registration&.ack_days || 3} working days" if req.mid}"
        end
      end

      def active_line(req, q)
        return "Renewed. #{req.child_name} rides in #{req.academic_year&.key}." if req.renew
        return "New pick-up: #{req.new_stop}" if req.kind == "adr"
        return "Confirmed at #{money(q || req.estimate)} a month from #{long(req.effective_on)}" if req.kind == "svc"

        "Service confirmed. Starts #{long(req.start_on)}."
      end

      # What a Change of Address / Change of Service / Stop asks for.
      def change(req)
        { effective_on: req.effective_on, what: what(req), old_address: req.old_address, new_address: req.address, new_postal: req.postal,
          new_stop: req.new_stop, update_home: req.new_home.present?, from_service: SHORT[old_service(req)], to_service: SHORT[service(req)],
          last_on: req.last_on, earliest_on: req.earliest_on, early: req.early, stop_reason: (req.stop_reason if req.kind == "stop"),
          notice: req.notice_n && { n: req.notice_n, unit: req.notice_unit }, pay_to: req.pay_to }
      end

      def old_service(req) = req.old_am && req.old_pm ? "both" : req.old_am ? "am" : req.old_pm ? "pm" : nil

      def what(req)
        case req.kind
        when "svc" then "#{SHORT[service(req)]}#{' + CCA Bus' if req.cca} from #{long(req.effective_on)}"
        when "stop" then "Last day #{long(req.last_on)}"
        when "adr" then "Move from #{long(req.effective_on)} · #{[ req.address, ("S#{req.postal}" if req.postal) ].compact.join(', ')}"
        else "Renewal for #{req.academic_year&.key} · #{SHORT[service(req)]}#{' + CCA Bus' if req.cca}"
        end
      end
    end
  end
end
