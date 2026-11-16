# Convoy App › Request School Bus (Bus Service Application, 3 steps): one request per child (kind new, source app) to the
# school's transport company for the year taking requests, with the level, start, sessions, pick-up / drop-off points,
# CCA bus and the fare estimate the parent saw. When the school's Payment & Refund Policy charges a registration fee,
# one bill (kind registration, a line per child) is issued at once and the requests wait on it (Fee Unpaid).
# Written inside the school's company; the Family and children stay platform records, linked by id. preview: true is the
# Review and Estimated Fare step: the same checks and fares, nothing saved.
module ConvoyApp
  module Parents
    class Submit < ApplicationService
      def initialize(member:, params:, preview: false)
        @member = member
        @household = member.household
        @account = member.app_account
        @params = params
        @preview = preview
      end

      def call
        school = Parents.school!(@params[:school_id])
        Parents.within(school.company) { submit(school) }
      end

      private

      def submit(school)
        today = Date.current
        win = Parents.window(school, today)
        raise Error, closed_text(school, win) unless win&.state == "open"

        kids = Array(@params[:children]).map { it.to_h.symbolize_keys }
        raise Error, "Choose at least one child" if kids.empty?

        policy = SchoolPolicyVersion.current_for(school.policy_versions, today)
        rows = kids.map { child(school, win, today, it) }
        dupes = rows.map { it[:dependant].id }
        raise Error, "Each child can be picked once" if dupes.uniq.size != dupes.size
        return review(school, win, policy, rows) if @preview
        raise Error, "Agree to the Transport Procedures and Safety Rules to continue" unless ActiveModel::Type::Boolean.new.cast(@params[:agree])

        now = Time.current
        ApplicationRecord.transaction do
          # One submission at a time per Family: a double tap (or two adults at once) finds the first one's requests.
          @household.lock!
          rows.each { |r| raise Error, "#{r[:dependant].first_name} already has a bus request for #{win.year.key}" if open_request?(r[:dependant], win.year) }
          reqs = rows.map { create(school, win, policy, now, it) }
          bill = registration_bill(school, win, policy, reqs, now) if policy&.registration_fee.to_d.positive?
          reqs.each do |req|
            text = "Sent from the Convoy App by #{@account.display_name}"
            text += ". Registration fee S$#{format('%.2f', policy.registration_fee)} invoiced (#{bill.number})" if bill
            req.log!(text, by: "Parent", at: now)
          end
          reqs
        end
      end

      # Step 3: per child the legs, start and fare; the totals and the registration fee paid now.
      def review(school, win, policy, rows)
        fee = policy&.registration_fee.to_d
        list = rows.map do |r|
          d = r[:dependant]
          { dependant_id: d.id, name: d.name, level: r[:level], student_id: r[:student_no], service: r[:am] && r[:pm] ? "both" : r[:am] ? "am" : "pm",
            start: r[:start].merge(text: Present.start_text(BusRequest.new(r[:start]))), pickup: r[:am] ? point_json(r[:main]) : nil,
            dropoff: r[:pm] ? point_json(r[:dropoff] || r[:main]) : nil, cca: r[:cca], cca_from: r[:cca_from], estimate: r[:est] }
        end
        fares = list.filter_map { it[:estimate][:amount] }
        { school: { id: school.id, name: school.name }, company: Parents.company_json(school.company), year: win.year.key, show_fare: win.registration.show_fare,
          children: list, riders: list.size, total: fares.size == list.size ? fares.sum(0.to_d) : nil,
          registration_fee: fee.positive? ? { each: fee, total: fee * list.size } : nil,
          note: Parents.mid?(win, Date.current) ? nil : "#{school.company.name} reviews in 1 to 2 weeks and sends the final quote. Once accepted, the first invoice is issued here" }
      end

      def point_json(p) = p && p.slice(:home, :address, :postal)

      def closed_text(school, win)
        return "#{school.name} is not taking bus requests yet" unless win

        win.state == "soon" ? "#{school.name} opens bus requests on #{Parents.long(win.opens_on)}" : "Bus requests for #{school.name} closed on #{Parents.long(win.closes_on)}"
      end

      # One child's step 2, checked as the HTML does (appNext), with the fare estimate.
      def child(school, win, today, k)
        dep = @household.dependants.find { it.id == k[:dependant_id].to_i } or raise Error, "Choose a child from your Family"
        raise Error, "#{dep.first_name} goes to #{dep.school_name}, not #{school.name}" unless dep.school_name.to_s.casecmp?(school.name)
        raise Error, "#{dep.first_name} already has a bus request for #{win.year.key}" if open_request?(dep, win.year)
        raise Error, "#{dep.first_name} already rides the bus at #{school.name}" if riding?(dep, school, today)

        level = k[:level].to_s.squish
        raise Error, "Choose the level" if level.empty?

        service = SERVICES.key?(k[:service].to_s) ? k[:service].to_s : "both"
        sessions = win.registration.sessions
        am = service != "pm"
        pm = service != "am"
        raise Error, "#{school.name} has no morning bus to ask for" if am && !sessions.include?("AM")
        raise Error, "#{school.name} has no afternoon bus to ask for" if pm && !sessions.include?("PM")

        pickup = Parents.point(@household, k[:pickup], label: "pick-up") if am
        dropoff = Parents.point(@household, k[:dropoff], label: "drop-off") if pm
        start = Parents.start_for(win, today, **k.slice(:start_when, :start_on, :fix_why, :fix_note))
        cca = ActiveModel::Type::Boolean.new.cast(k[:cca]) || false
        raise Error, "#{school.name} has no CCA bus to ask for" if cca && !sessions.include?("CCA")

        main = pickup || dropoff
        est = Estimate.call(school:, year: win.year, point: main, am:, pm:, cca:, start_on: start[:start_on], registration: win.registration)
        { dependant: dep, level:, student_no: k[:student_id].to_s.squish.presence || dep.student_id, am:, pm:, main:,
          dropoff: (dropoff if am && pm && dropoff[:address] != pickup[:address]), start:, cca:,
          cca_from: cca ? cca_from(win.year, start[:start_on], k[:cca_from]) : nil, est: }
      end

      def open_request?(dep, year)
        BusRequest.where(dependant_id: dep.id, kind: "new", academic_year: year).where.not(status: %w[Withdrawn Declined]).any? { it.live_status != "Lapsed" }
      end

      def riding?(dep, school, today)
        rids = FamilyRider.where(school:, dependant_id: dep.id).select(:rid)
        SchoolRider.where(school:, rid: rids).where(ends_on: [ nil, today.. ]).exists?
      end

      # CCA Bus From: the start of the CCA term (the first CCA / ASA period from the bus start) or a date in the year.
      def cca_from(year, start, value)
        if value.present? && value.to_s != "cca"
          date = Date.parse(value.to_s)
          raise Error, "Pick a CCA bus start from #{Parents.long(start)}" if date < start || date > year.ends_on

          return date
        end
        starts = year.terms.map { year.cca_same_as_terms ? it.starts_on : it.cca_starts_on }.compact.sort
        starts.find { it >= start } || start
      rescue Date::Error
        raise Error, "Pick the CCA bus start date"
      end

      def create(school, win, policy, now, row)
        dep = row[:dependant]
        main = row[:main]
        school.bus_requests.create!(
          academic_year: win.year, kind: "new", source: "app", status: "Requested", submitted_at: now, household: @household, dependant: dep,
          app_account: @account, child_name: dep.name, birth_date: dep.birth_date, level: row[:level], student_no: row[:student_no],
          medical: [ dep.medical_tags.join(", ").presence, dep.medical_note ].compact.join(". ").presence, am: row[:am], pm: row[:pm],
          address: main[:address], postal: main[:postal], lat: main[:lat], lng: main[:lng],
          dropoff_address: row[:dropoff]&.dig(:address), dropoff_postal: row[:dropoff]&.dig(:postal), dropoff_lat: row[:dropoff]&.dig(:lat),
          dropoff_lng: row[:dropoff]&.dig(:lng), cca: row[:cca], cca_from: row[:cca_from], estimate: row[:est][:amount], km: row[:est][:km],
          mid: Parents.mid?(win, now.to_date), terms_agreed_at: now, policy_version: policy&.version,
          fee_paid: !policy&.registration_fee.to_d.positive?, **row[:start], **Parents.parent(@account)
        )
      end

      def registration_bill(school, win, policy, reqs, now)
        settings = FinanceSetting.current
        fee = policy.registration_fee.to_d
        split = FinanceSetting.split(fee * reqs.size, on: settings.gst_on?, rate: settings.gst_rate, mode: settings.gst_mode)
        parent = Parents.parent(@account)
        bill = SchoolBill.create!(school:, academic_year: win.year, kind: "registration", status: "issued", number: Finance::Numbering.next!("inv", settings:),
                                  bill_to: parent[:parent_name], bill_to_email: parent[:parent_email], period_label: "Registration · AY#{win.year.key}",
                                  issued_on: now.to_date, issued_at: now, due_on: now.to_date, due_at: now, subtotal: split[:sub],
                                  gst_rate: settings.gst_on? ? settings.gst_rate : 0, gst_amount: split[:gst], total: split[:total])
        reqs.each_with_index do |req, i|
          bill.lines.create!(position: i, child_name: req.child_name, amount: fee, description: "#{req.child_name} | Registration fee · #{school.name}")
          req.update!(registration_bill: bill)
        end
        bill
      end
    end
  end
end
