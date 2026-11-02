# Needs a Look: finds unusual fills of the last 90 days across the company's own buses and keeps fuel_alerts in step
# (new findings open, ones that no longer apply removed, Mark Checked kept). The checks, per bus:
#   eff    efficiency more than 30% off the bus's median for that energy (3+ measures)
#   odo    odometer lower than the reading before
#   dbl    two fills of the same energy less than 60 km or 6 hours apart
#   big    a fill more than 1.6 × the bus's median fill (4+ fills)
#   price  price per unit more than 15% above the fleet's median for that kind
#   trend  energy per km in the last 30 days more than 18% above the 30 days before (each over 300 km)
# Run after an entry is saved or deleted, and daily (findings age out after 90 days).
module FuelAlerts
  class Scan < ApplicationService
    DAYS = 90

    def initialize(today: Date.current)
      @today = today
      @since = today - DAYS
    end

    def call
      entries = FuelEntry.includes(:vehicle).where(date: (@today - 400)..@today).chronological.to_a
      @prices = entries.group_by(&:kind).transform_values { |l| median(l.map(&:unit_price).compact) }
      found = entries.group_by(&:vehicle_id).flat_map { |_, list| for_vehicle(list) }.select { |a| a[:date] >= @since }
      save(found)
    end

    private

    def for_vehicle(list)
      out = []
      usual_eff = list.select(&:efficiency).group_by { |e| e.elec? ? "elec" : "fuel" }
                      .transform_values { |l| l.size >= 3 ? median(l.map(&:efficiency)) : nil }
      fills = list.group_by(&:energy).transform_values { |l| l.map(&:quantity) }
      last = {}
      list.each do |e|
        g = e.energy
        out << efficiency(e, usual_eff[e.elec? ? "elec" : "fuel"]) if e.efficiency && usual_eff[e.elec? ? "elec" : "fuel"]
        out << finding(e, "odo", "warn", "km", "Odometer #{km(e.odometer)} is lower than the last reading of #{km(e.odometer_back)}") if e.odometer_back
        out << close_together(e, last[g]) if last[g] && g != "def"
        if g != "def" && fills[g].size >= 4 && e.quantity > median(fills[g]) * 1.6
          out << finding(e, "big", "warn", g == "elec" ? "elec" : "fuel", "Filled #{num(e.quantity)} #{e.unit}, far more than the usual #{num(median(fills[g]).round(1))} #{e.unit}")
        end
        usual = @prices[e.kind]
        if usual&.positive? && e.unit_price && e.unit_price > usual * 1.15
          out << finding(e, "price", "warn", "spend",
                         "Paid #{money(e.unit_price)} per #{e.unit}, #{((e.unit_price / usual - 1) * 100).round}% above the usual #{money(usual)}")
        end
        last[g] = e
      end
      out.compact + trends(list)
    end

    def efficiency(e, usual)
      d = (e.efficiency - usual) / usual
      return if d.abs <= 0.3

      pct = (d.abs * 100).round
      worse = e.elec? ? d.positive? : d.negative?
      text = e.elec? ? "#{num(e.efficiency)} kWh/100km, uses #{pct}% #{d.positive? ? 'more' : 'less'} than usual" : "#{num(e.efficiency)} km/L, #{pct}% #{worse ? 'worse' : 'better'} than usual"
      finding(e, "eff", worse ? "warn" : "info", e.elec? ? "elec" : "eff", worse ? text : "#{text}. A fill may not have been recorded")
    end

    def close_together(e, prev)
      hours = ((at(e) - at(prev)) / 3600.0)
      return unless (e.energy_km && e.energy_km < 60) || hours < 6

      gap = e.energy_km ? "#{e.energy_km} km" : "#{[ hours.round, 0 ].max} h"
      what = e.elec? ? "charges" : "fills"
      finding(e, "dbl", "warn", e.elec? ? "elec" : "fuel", "Two #{what} #{gap} apart (#{num(prev.quantity)} #{e.unit}, then #{num(e.quantity)} #{e.unit})")
    end

    def trends(list)
      %w[fuel elec].filter_map do |g|
        measured = list.select { |e| e.energy == g && e.energy_km }
        recent = measured.select { |e| e.date > @today - 30 }
        before = measured.select { |e| e.date > @today - 60 && e.date <= @today - 30 }
        k1, k0 = recent.sum(&:energy_km), before.sum(&:energy_km)
        q1, q0 = recent.sum(&:quantity), before.sum(&:quantity)
        next unless k1 > 300 && k0 > 300 && q1.positive? && q0.positive?

        d = (q1 / k1) / (q0 / k0) - 1
        next unless d > 0.18

        e = recent.last
        finding(e, "trend", "warn", g == "elec" ? "elec" : "eff",
                "Used #{(d * 100).round}% more #{g == 'elec' ? 'energy' : 'fuel'} per km in the last 30 days than in the 30 days before",
                key: "trend:#{e.vehicle_id}:#{g}:#{@today.strftime('%Y-%m')}")
      end
    end

    def finding(e, kind, tone, metric, message, key: nil)
      { key: key || "#{kind}:#{e.id}", kind:, tone:, metric:, message:, date: e.date, vehicle_id: e.vehicle_id, fuel_entry_id: e.id }
    end

    def save(found)
      FuelAlert.transaction do
        FuelAlert.where.not(key: found.map { |a| a[:key] }).delete_all
        existing = FuelAlert.where(key: found.map { |a| a[:key] }).index_by(&:key)
        found.each do |a|
          alert = existing[a[:key]] || FuelAlert.new(key: a[:key])
          alert.assign_attributes(a.except(:key))
          alert.save! if alert.changed?
        end
      end
    end

    def at(e) = e.date.to_time + (e.time || 720).minutes
    def median(values) = values.sort[values.size / 2]
    def km(n) = "#{ActiveSupport::NumberHelper.number_to_delimited(n)} km"
    def num(d) = d.to_d.to_s("F").sub(/\.0\z/, "")
    def money(d) = "S$#{format('%.2f', d)}"
  end
end
