# The final quote suggestion for a new request (Convoy OS reqBase): the Bus Fares tier for the distance from school
# (the year's locked table, else the latest locked one before it), for the bill the start date falls in — two ways, or
# one way when only AM or PM; else the estimate the parent saw.
module BusRequests
  module Fare
    module_function

    def base(req)
      year = req.academic_year
      table = table_for(req.school, year)
      km = req.km&.to_f || (req.lat && req.school.lat && RouteFit.km([ req.school.lat.to_f, req.school.lng.to_f ], [ req.lat.to_f, req.lng.to_f ]))
      if table.nil? || km.nil? || table.per_bus? || table.zones? || table.tiers.empty?
        return { amount: req.estimate.to_d.round(2), unit: unit(table, year), km:,
                 text: "No saved Bus Fares table, so this is the estimate the parent saw" }
      end

      tiers = table.tiers.sort_by { it.max_km&.to_f || Float::INFINITY }
      i = tiers.index { it.max_km && km <= it.max_km.to_f } || (tiers.size - 1)
      i = table.tiers.index(tiers[i])
      periods = FareTables.periods(table.academic_year, table)
      row = FareTables::Calc.call(table, periods)[i]
      both = req.am && req.pm
      kind = both ? (row[:std][:two] ? :two : :one) : (table.trip == "ampm" ? (req.am ? :am : :pm) : :one)
      fares = row[:std][kind] || row[:std][:two]
      k = periods.index { req.start_on && it[:starts_on] && it[:starts_on] <= req.start_on && req.start_on <= it[:ends_on] } || 0
      amount = fares[:periods][k] || fares[:periods].first
      other = table.academic_year_id == year&.id ? "" : " (AY #{year&.key} has no saved fares yet)"
      { amount:, unit: unit(table, year), km: km.round(1), tier: i + 1,
        text: "Bus Fares AY #{table.academic_year.key}#{other}: #{km.round(1)} km from school, #{row[:label]}#{', one way' unless both}, " \
              "S$#{format('%.2f', amount)} a #{unit(table, year)}" }
    end

    def table_for(school, year)
      return unless year

      list = school.academic_years.includes(fare_table: %i[tiers academic_year], setup_locks: []).select { it.fare_table&.locked? }
      list.find { it.id == year.id }&.fare_table || list.select { it.starts_on <= year.starts_on }.max_by(&:starts_on)&.fare_table ||
        list.max_by(&:starts_on)&.fare_table
    end

    def unit(table, year) = table&.cycle == "month" || table.nil? ? "month" : (year&.period_label || "term").downcase

    # The billing period the start date falls in, for the first invoice.
    def first_period(req)
      table = table_for(req.school, req.academic_year)
      list = table ? FareTables.periods(table.academic_year, table) : []
      p = list.find { req.start_on && it[:starts_on] && it[:starts_on] <= req.start_on && req.start_on <= it[:ends_on] } || list.first
      return { label: p[:label], starts_on: p[:starts_on] } if p && table.academic_year_id == req.academic_year_id

      d = req.start_on || Date.current
      { label: "#{FareTables::MONTHS[d.month - 1]} #{d.year}", starts_on: d.beginning_of_month }
    end
  end
end
