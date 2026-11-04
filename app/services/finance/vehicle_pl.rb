# Vehicle Financials > profit and loss of own vehicles by month (port of the prototype's vfPL), worked out live:
#   revenue  "<trip kind> (auto)": client price of runs on the bus (not cancelled, up to today); "School Bus (auto)": the
#            route pay of School Bus routes the bus runs (what an operator bus would be paid); manual revenue entries.
#   cost     "Insurance Premium (auto)" spread over the cover months; "Fuel and Energy (auto)"; "Maintenance (auto)" (completed
#            visits with GST); manual cost entries; "Driver Salary (auto)" + "Employer CPF (auto)": each default driver's
#            scheme pay for the month with no jobs (fixed pay and top-up) × the share of the month they were on the bus;
#            basis profit: "Depreciation" (price over the months to COE expiry, else 120) + "Loan Interest";
#            basis cash: "Purchase" / "Down Payment" in the buying month + "Loan Instalments".
# Result: { vehicle_id => { Date(month) => [{ kind, category, amount, path }] } }; path = the dive (level 1, level 2) as the
# prototype: trips client → trip, School Bus school → route, fuel kind → company, maintenance line type → item | workshop,
# driver pay the driver, CPF "<driver> at x%", entries their note.
module Finance
  class VehiclePl < ApplicationService
    KIND_LABEL = Trip::KIND_NAMES.merge("corporate_shuttle" => "Shuttle")

    def initialize(vehicles:, from:, to:, basis: "profit", today: Date.current)
      @vehicles = vehicles
      @ids = vehicles.map(&:id)
      @from = from.beginning_of_month
      @to = [ to.end_of_month, today.end_of_month ].min
      @basis = basis
      @today = today
      @out = Hash.new { |h, v| h[v] = Hash.new { |m, k| m[k] = [] } }
    end

    def call
      trip_revenue
      school_bus_revenue
      entries
      insurance
      fuel
      maintenance
      drivers
      purchase
      @out
    end

    private

    def add(vehicle_id, date, kind, category, amount, path = nil)
      month = date.beginning_of_month
      return if month < @from || month > @to || amount.to_d.zero?

      @out[vehicle_id][month] << { kind:, category:, amount: amount.to_d.round(2), path: Array(path).compact_blank.presence }
    end

    def trip_revenue
      sums = TripOccurrence.where(vehicle_id: @ids).between(@from, [ @to, @today ].min).where.not(status: %w[cancelled removed skipped])
                           .where("price > 0").group(:vehicle_id, Arel.sql("date_trunc('month', date)::date"), :kind, :client_id, :trip_id).sum(:price)
      clients = Client.where(id: sums.keys.map { it[3] }.compact.uniq).pluck(:id, :name).to_h
      trips = Trip.where(id: sums.keys.map { it[4] }.compact.uniq).pluck(:id, :title).to_h
      sums.each do |(vid, month, kind, client_id, trip_id), sum|
        label = KIND_LABEL[kind] || kind.humanize
        add(vid, month, "revenue", "#{label} (auto)", sum, [ clients[client_id].presence || "No client set", trips[trip_id].presence || label ])
      end
    end

    # School Bus routes the company's own buses run: each month's route pay (SchoolPay::Cost) by school and route.
    def school_bus_revenue
      month = @from
      last = [ @to, @today ].min
      # Only schools whose routes ever had one of these buses (route pay is worked out per school and month).
      used = SchoolRouteVehicleChange.where(vehicle_id: @ids).joins(route: :plan).merge(SchoolPlan.where(in_use: true)).select("school_plans.school_id")
      schools = School.where(id: used).to_a
      while month <= last
        schools.each do |school|
          SchoolPay::Cost.call(school, month)[:rows].each do |r|
            next unless r.vehicle && @ids.include?(r.vehicle.id)

            add(r.vehicle.id, month, "revenue", "School Bus (auto)", r.amount, [ school.name, r.route.label ])
          end
        end
        month = month.next_month
      end
    end

    def entries
      VehicleFinanceEntry.where(vehicle_id: @ids).find_each do |e|
        month = @from
        while month <= @to
          add(e.vehicle_id, month, e.kind, e.category, e.amount, e.note.to_s.strip.presence || (e.kind == "revenue" ? "Entered without a note" : "No note")) if e.in_month?(month)
          month = month.next_month
        end
      end
    end

    # Premium (before GST) spread evenly over the cover months (open-ended: 12, at most 60), the remainder on the last.
    def insurance
      VehicleInsurancePolicy.where(vehicle_id: @ids).where.not(premium: nil).where.not(starts_on: nil).find_each do |p|
        months = p.ends_on ? [ ((p.ends_on.year * 12) + p.ends_on.month) - ((p.starts_on.year * 12) + p.starts_on.month) + 1, 1 ].max : 12
        months = [ months, 60 ].min
        each_month = (p.premium / months).round(2)
        months.times do |i|
          amount = i == months - 1 ? p.premium - (each_month * (months - 1)) : each_month
          add(p.vehicle_id, p.starts_on.beginning_of_month >> i, "cost", "Insurance Premium (auto)", amount)
        end
      end
    end

    def fuel
      sums = FuelEntry.where(vehicle_id: @ids, date: @from..@to).group(:vehicle_id, Arel.sql("date_trunc('month', date)::date"), :kind, :fuel_company_id).sum(:cost)
      companies = FuelCompany.where(id: sums.keys.map(&:last).compact.uniq).pluck(:id, :name).to_h
      sums.each do |(vid, month, kind, company_id), sum|
        add(vid, month, "cost", "Fuel and Energy (auto)", sum, [ FuelEntry::KINDS.dig(kind, :name) || "Fuel", companies[company_id] || "Company not set" ])
      end
    end

    LINE_TYPES = { "part" => "Parts", "tyre" => "Tyres", "labour" => "Labour", "other" => "Other" }.freeze

    # Each line with its share of the GST, by line type then "item, tyre position | workshop".
    def maintenance
      MaintenanceVisit.completed.where(vehicle_id: @ids, date: @from..@to).includes(:lines, :workshop).find_each do |v|
        sub = v.subtotal
        rate = sub.positive? ? v.total / sub : 1
        v.lines.each do |l|
          item = [ l.description.presence || LINE_TYPES[l.line_type], (l.tyre_position if l.tyre?) ].compact_blank.join(", ")
          add(v.vehicle_id, v.date, "cost", "Maintenance (auto)", l.amount * rate, [ LINE_TYPES[l.line_type], [ item, v.workshop&.name ].compact_blank.join(" | ") ])
        end
      end
    end

    def drivers
      schedules = VehicleDriverSchedule.where(vehicle_id: @ids).order(:starts_on, :start_time).group_by(&:vehicle_id)
      salary = {}
      month = [ @from, @today.beginning_of_month << 35 ].max
      while month <= [ @to, @today ].min
        days = month.end_of_month.day
        schedules.each do |vid, list|
          counts = Hash.new(0)
          (month..month.end_of_month).each { |d| (did = list.select { |s| s.starts_on <= d }.last&.driver_id) && counts[did] += 1 }
          counts.each do |did, n|
            driver = Driver.find_by(id: did) or next
            pay = salary[[ did, month ]] ||= month_pay(driver, month)
            share = n.to_d / days
            kyc = driver.kyc_profile
            cpf = Finance::Cpf.employer(pay, kyc&.date_of_birth, month, kyc&.residential_status)
            add(vid, month, "cost", "Driver Salary (auto)", pay * share, driver.name)
            add(vid, month, "cost", "Employer CPF (auto)", cpf[:amount] * share, "#{driver.name}#{" at #{cpf[:rate]}%" if cpf[:rate].to_d.positive?}")
          end
        end
        month = month.next_month
      end
    end

    # The scheme pay of a month with no jobs (fixed pay and guarantee top-up), as the prototype estimates it.
    def month_pay(driver, month)
      scheme = Pay::DriverTerms.new(driver, from: month, to: month).scheme_on(month)
      return 0.to_d unless scheme

      Pay::Engine.new(scheme:, from: month, to: month.end_of_month, month_days: month.end_of_month.day, holidays: Set.new, jobs: []).call.total
    end

    def purchase
      VehicleFinancial.where(vehicle_id: @ids).includes(:payments, :vehicle).find_each do |f|
        s = f.schedule(@today)
        next unless f.bought_on

        if @basis == "cash"
          f.funded_by_cash? ? add(f.vehicle_id, f.bought_on, "cost", "Purchase", f.purchase_price) : add(f.vehicle_id, f.bought_on, "cost", "Down Payment", s.down)
          s.rows.each { |r| add(f.vehicle_id, r.due_on, "cost", "Loan Instalments", r.amount) }
        else
          depreciation(f)
          s.rows.each { |r| add(f.vehicle_id, r.due_on, "cost", "Loan Interest", r.interest) }
        end
      end
    end

    def depreciation(f)
      return unless f.purchase_price.to_d.positive?

      start = f.bought_on.beginning_of_month
      coe = f.vehicle.coe_expires_on&.beginning_of_month
      life = coe && coe > start ? ((coe.year * 12) + coe.month) - ((start.year * 12) + start.month) : 120
      per = f.purchase_price / life
      life.times { |i| add(f.vehicle_id, start >> i, "cost", "Depreciation", per) }
    end
  end
end
