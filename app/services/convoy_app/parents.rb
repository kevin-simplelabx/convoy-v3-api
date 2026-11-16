# Convoy App › School Bus, the parent side: the companies a Family deals with, a school's registration window as parents
# see it, the start options of a request and the money a parent may see. A Family is platform-wide; every company record
# (requests, riders, bills) is read and written inside its own company and time zone (`within`), found through the
# Family's ids (bus_requests.household_id, families.household_id), never by a blanket read across companies.
module ConvoyApp
  module Parents
    # state open | soon | closed; opens_on = renewals or everyone (by kind), closes_on = everyone's last day.
    Window = Data.define(:state, :year, :registration, :opens_on, :closes_on, :starts_on, :ends_on)
    WHEN = { "first" => "From the First School Day", "asap" => "As Soon As Possible", "pref" => "Preferred Date", "fixed" => "Fixed Date" }.freeze
    FIX_WHY = { "move" => "Moving House", "ready" => "Not Ready Before Then", "other" => "Other Reason" }.freeze
    SERVICES = { "both" => "Two Ways", "am" => "One Way Morning", "pm" => "One Way Afternoon" }.freeze

    module_function

    # Run inside a company and its time zone (so "today" is the company's).
    def within(company, &) = ActsAsTenant.with_tenant(company) { Time.use_zone(company.timezone.presence || Time.zone, &) }

    # Companies holding this Family's School Bus records: its requests and the families accepting copied it into.
    def companies(household)
      ids = ActsAsTenant.without_tenant do
        BusRequest.where(household_id: household.id).distinct.pluck(:company_id) | Family.where(household_id: household.id).distinct.pluck(:company_id)
      end
      Company.where(id: ids).order(:id).to_a
    end

    # Every school with this name at an active company (the providers a parent can ask). The platform directory, read
    # across companies on purpose; each school's data is then read inside its own company.
    def schools_named(name)
      ActsAsTenant.without_tenant do
        School.includes(:company).where(company_id: Company.active.select(:id)).where("LOWER(name) = ?", name.to_s.strip.downcase).order(:id).to_a
      end
    end

    # A school of an active company by id (the provider a request goes to), else 404.
    def school!(id)
      ActsAsTenant.without_tenant { School.includes(:company).where(company_id: Company.active.select(:id)).find(id) }
    end

    # The registration a parent can use at a school (Convoy OS regWin): the year taking requests today, else the next to
    # open, else the last closed; nil when none is scheduled. New requests open with everyone (general_from), renewals
    # with the early window (renew_from), for a year that has not started yet; both close at general_to. Call inside the
    # school's company.
    def window(school, today, renew: false)
      regs = SchoolRegistration.where(school:, status: "scheduled").includes(academic_year: :terms).to_a
      regs = regs.select { it.academic_year.starts_on > today } if renew
      list = regs.map { |r| [ r, renew ? r.renew_from : r.general_from ] }.sort_by(&:last)
      return if list.empty?

      open = list.find { |r, from| from <= today && today <= r.general_to }
      nxt = list.find { |_, from| from > today }
      reg, from = open || nxt || list.last
      Window.new(state: open ? "open" : nxt ? "soon" : "closed", year: reg.academic_year, registration: reg, opens_on: from,
                 closes_on: reg.general_to, starts_on: reg.service_starts_on, ends_on: reg.academic_year.ends_on)
    end

    # Mid-year: the year's service has started and its form is still open (requests.js midNow).
    def mid?(win, today) = win&.state == "open" && win.starts_on <= today

    # The next 8 Mondays after today (start dates offered mid-year and for Change From).
    def mondays(today)
      first = today + 1
      first += 1 until first.monday?
      Array.new(8) { first + (it * 7) }
    end

    def next_weekday(date)
      date += 1 while date.saturday? || date.sunday?
      date
    end

    # The start a child asked for: { start_when:, start_on: } (HTML kWhen). Before term: the first school day or a date;
    # mid-year: as soon as possible (next weekday) or a date. Raises with the HTML's wording when the date cannot be used.
    def start_for(win, today, start_when: nil, start_on: nil, fix_why: nil, fix_note: nil)
      mid = mid?(win, today)
      w = start_when.to_s
      w = mid ? "asap" : "first" if w.blank? || (mid ? w == "first" : w == "asap")
      raise ApplicationService::Error, "Pick when the bus should start" unless WHEN.key?(w)
      return { start_when: "first", start_on: win.starts_on } if w == "first"
      return { start_when: "asap", start_on: next_weekday(today + 1) } if w == "asap"

      date = start_on.presence && Date.parse(start_on.to_s)
      raise ApplicationService::Error, "Pick a start date from tomorrow" if date.nil? || date <= today
      raise ApplicationService::Error, "Pick a date from the first school day, #{long(win.starts_on)}" if !mid && date < win.starts_on
      if date > win.ends_on
        raise ApplicationService::Error, "Pick a date in the #{win.year.key} school year, up to #{long(win.ends_on)}. Requests for a later year open with its registration"
      end

      out = { start_when: w, start_on: date, fix_why: nil, fix_note: nil }
      return out unless w == "fixed"

      why = FIX_WHY.key?(fix_why.to_s) ? fix_why.to_s : "move"
      note = fix_note.to_s.strip
      raise ApplicationService::Error, "Say why the bus has to start on this date" if why == "other" && note.empty?

      out.merge(fix_why: why, fix_note: why == "other" ? note : nil)
    rescue Date::Error
      raise ApplicationService::Error, "Pick a start date from tomorrow"
    end

    def long(date) = date&.strftime("%-d %b %Y")

    # A pick-up or drop-off point: the Family's home, or another point typed as a postal code and "Block, street, unit",
    # placed on the map by OneMap when it knows the code. { home:, address:, postal:, lat:, lng: }
    def point(household, input, label:)
      input = (input || {}).to_h.symbolize_keys
      if input[:point].to_s == "other"
        postal = input[:postal].to_s.gsub(/\D/, "")
        address = input[:address].to_s.squish
        raise ApplicationService::Error, "Enter the #{label} postal code and address" unless postal.match?(/\A\d{6}\z/) && address.present?

        hit = locate(postal)
        return { home: false, address:, postal:, lat: hit&.dig(:lat), lng: hit&.dig(:lng) }
      end
      hit = household.lat ? { lat: household.lat, lng: household.lng } : locate(household.postal)
      { home: true, address: household.address, postal: household.postal, lat: hit&.dig(:lat), lng: hit&.dig(:lng) }
    end

    def locate(postal)
      Geo::OneMap.lookup(postal)
    rescue Geo::OneMap::Unavailable
      nil
    end

    # The adult who sends a request, as the company sees them: name, mobile and an email (personal first).
    def parent(account)
      email = account.identities.select { it.kind == "email" && it.verified_at }.min_by { it.tag == "personal" ? 0 : 1 }
      { parent_name: account.display_name, parent_phone: account.mobile&.value, parent_email: email&.value }
    end

    # Money on requests and bills is the Billing Contact's only (registration fee and first invoice amounts, Pay).
    def billing?(member) = member&.billing_contact?

    # Company name and the two-letter mark the app shows on School Bus screens ("SimpleDrive" -> "SD").
    def company_json(company)
      name = company.short_name.presence || company.name
      caps = name.to_s.scan(/[A-Z]/)
      { id: company.id, name: company.name, mark: (caps.size >= 2 ? caps.join : name.to_s.split.map { it[0] }.join).first(2).upcase }
    end
  end
end
