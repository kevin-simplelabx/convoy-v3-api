# The Usage card of Fuel & Energy: one measure over a period against the period before, all buses or by vehicle,
# driver or company, with a breakdown and a short read of the situation.
#   view     all | vehicle | driver | company, key: the one picked (vehicle / driver / fuel company id, "none" = not set)
#   measure  spend | fuel (L) | elec (kWh) | def (L) | km | eff (km/L, fuel only) | cpk (cost per km)
#   range    30d (by day) | 12w (by week from Monday) | 12m (by month); zoom_from / zoom_to: the days of one week or month
# The period before: the same buckets 30 days / 12 weeks / 12 months earlier; a zoomed month against the month before,
# a zoomed week against the week before. Buckets are filled by groupdate (every bucket present, 0 when empty).
class FuelUsage
  MEASURES = %w[spend fuel elec def km eff cpk].freeze
  VIEWS = { "vehicle" => :vehicle_id, "driver" => :driver_id, "company" => :fuel_company_id }.freeze
  FUEL = "kind IN ('diesel', 'petrol')".freeze
  SUMS = {
    spend: "cost", km: "COALESCE(km_since, 0)",
    fuel: "CASE WHEN #{FUEL} THEN quantity ELSE 0 END", elec: "CASE WHEN kind = 'elec' THEN quantity ELSE 0 END",
    def: "CASE WHEN kind = 'def' THEN quantity ELSE 0 END", fuel_km: "CASE WHEN #{FUEL} THEN COALESCE(energy_km, 0) ELSE 0 END"
  }.freeze
  NEEDS = { "eff" => %i[fuel_km fuel], "cpk" => %i[spend km] }.freeze
  # Higher is better for efficiency, lower for spend, fuel and cost per km; distance is neither.
  BETTER = { "eff" => "higher", "km" => nil }.freeze

  def initialize(scope, params, today: Date.current)
    @all = scope
    @view = VIEWS.key?(params[:view]) ? params[:view] : "all"
    @key = @view == "all" ? nil : params[:key].presence
    @measure = MEASURES.include?(params[:measure]) ? params[:measure] : "spend"
    @range = %w[30d 12w 12m].include?(params[:range]) ? params[:range] : "12m"
    @zoom = params[:zoom_from].present? && params[:zoom_to].present? ? Date.parse(params[:zoom_from])..Date.parse(params[:zoom_to]) : nil
    @today = today
  end

  def call
    cur, prev, group = periods
    scope = filtered(@all)
    current = series(scope, cur, group)
    before = series(scope, prev, group)
    total = value(totals(scope.where(date: cur)))
    total_before = value(totals(scope.where(date: prev)))
    {
      view: @view, key: @key, measure: @measure, range: @range, zoomed: @zoom.present?, by: group,
      period: { from: cur.first, to: cur.last }, before: { from: prev.first, to: prev.last },
      buckets: current.each_with_index.map { |(from, v), i| { from:, current: v, before: before[i]&.last } },
      total:, total_before:, change_pct: change(total, total_before), better: BETTER.fetch(@measure, "lower"),
      rows: @view == "all" ? [] : rows(cur, prev),
      drivers: @view == "driver" ? driver_use(cur, prev).values : [],
      summary: summary(scope, cur, prev)
    }
  end

  private

  # [current days, days before, bucket]
  def periods
    if @zoom
      days = @zoom.count
      whole_month = @zoom.first == @zoom.first.beginning_of_month && @zoom.last == @zoom.first.end_of_month
      before = whole_month ? @zoom.first.prev_month.all_month : (@zoom.first - days)..(@zoom.first - 1)
      [ @zoom, before, "day" ]
    else
      case @range
      when "30d" then [ (@today - 29)..@today, (@today - 59)..(@today - 30), "day" ]
      when "12w"
        start = @today.beginning_of_week(:monday) - 77
        [ start..@today, (start - 84)..(start - 1), "week" ]
      else
        start = (@today << 11).beginning_of_month
        [ start..@today, (start << 12)..(start - 1), "month" ]
      end
    end
  end

  def filtered(scope)
    return scope unless @key

    column = VIEWS[@view]
    @key == "none" ? scope.where(column => nil) : scope.where(column => @key)
  end

  # [[bucket start, value]] for every bucket of the days.
  def series(scope, days, group)
    parts = (NEEDS[@measure] || [ @measure.to_sym ]).to_h do |part|
      options = group == "week" ? { range: days, week_start: :monday } : { range: days }
      [ part, scope.public_send(:"group_by_#{group}", :date, **options).sum(Arel.sql(SUMS[part])) ]
    end
    parts.values.first.keys.map { |d| [ d.to_date, value(parts.transform_values { |h| h[d] }) ] }
  end

  def totals(scope) = SUMS.keys.zip(scope.pick(*SUMS.values.map { |s| Arel.sql("COALESCE(SUM(#{s}), 0)") })).to_h

  def value(sums)
    case @measure
    when "eff" then sums[:fuel].to_d.positive? && sums[:fuel_km].to_d.positive? ? (sums[:fuel_km].to_d / sums[:fuel]).round(1) : nil
    when "cpk" then sums[:km].to_d.positive? ? (sums[:spend].to_d / sums[:km]).round(2) : nil
    else sums[@measure.to_sym].to_d.round(2)
    end
  end

  def change(now, before)
    now && before&.nonzero? ? ((now - before) / before * 100).round : nil
  end

  # Breakdown: each vehicle / driver / company with entries in either period, biggest first.
  def rows(cur, prev)
    column = VIEWS[@view]
    by_cur = grouped(@all.where(date: cur), column)
    by_prev = grouped(@all.where(date: prev), column)
    open = FuelAlert.open.joins(:fuel_entry).group("fuel_entries.#{column}").count
    names = names_for((by_cur.keys + by_prev.keys).uniq.compact)
    (by_cur.keys | by_prev.keys).map do |k|
      now = value(by_cur[k] || {})
      before = value(by_prev[k] || {})
      { key: k&.to_s || "none", name: names[k] || none_name, current: now, before:, change_pct: change(now, before),
        alerts: open[k].to_i }
    end.sort_by { |r| -(r[:current] || 0) }
  end

  def grouped(scope, column)
    scope.group(column).pluck(column, *SUMS.values.map { |s| Arel.sql("COALESCE(SUM(#{s}), 0)") })
         .to_h { |k, *vals| [ k, SUMS.keys.zip(vals).to_h ] }
  end

  def names_for(ids)
    case @view
    when "vehicle" then Vehicle.with_discarded.where(id: ids).pluck(:id, :plate).to_h
    when "driver" then Driver.with_discarded.where(id: ids).pluck(:id, :name).to_h
    else FuelCompany.where(id: ids).pluck(:id, :name).to_h
    end
  end

  def none_name = { "driver" => "No driver set", "company" => "Company not set" }.fetch(@view, "Removed vehicle")

  # Fuel per km of each driver against the usual for the buses they drove: every fill (fuel, with km since the
  # previous fill) is compared with the usual km/L of that bus when other drivers drove it (3+ fills), else with buses
  # of its size (under 19 seats, 19 to 39, 40 and up). excess_pct > 10 = uses more fuel than usual.
  def driver_use(cur, prev)
    fills = @all.where(kind: %w[diesel petrol]).where("energy_km > 0").where(date: (@today - 365)..@today)
                .includes(:vehicle).to_a
    band = ->(e) { s = e.vehicle.seats.to_i; s >= 40 ? :large : s >= 19 ? :medium : :small }
    rate = ->(e) { e.energy_km / e.quantity }
    by_band = fills.group_by(&band).transform_values { |l| median(l.map(&rate)) }
    usual = lambda do |e|
      others = fills.select { |o| o.vehicle_id == e.vehicle_id && o.driver_id != e.driver_id }.map(&rate)
      others.size >= 3 ? median(others) : by_band[band.call(e)]
    end
    index = lambda do |list|
      measured = list.select { |e| e.driver_id && usual.call(e) }
      expected = measured.sum { |e| e.energy_km / usual.call(e) }
      expected.positive? ? { pct: ((measured.sum(&:quantity) / expected - 1) * 100).round, km: measured.sum(&:energy_km),
                             vehicles: measured.map { |e| e.vehicle.plate }.uniq.sort } : nil
    end
    names = Driver.with_discarded.where(id: fills.map(&:driver_id).compact.uniq).pluck(:id, :name).to_h
    fills.group_by(&:driver_id).except(nil).to_h do |driver_id, list|
      now = index.call(list.select { |e| cur.cover?(e.date) })
      before = index.call(list.select { |e| prev.cover?(e.date) })
      [ driver_id, { driver_id:, name: names[driver_id], excess_pct: now&.dig(:pct), excess_pct_before: before&.dig(:pct),
                     km: now&.dig(:km).to_i, vehicles: now&.dig(:vehicles) || [] } ]
    end.select { |_, d| d[:excess_pct] }
  end

  # A short read: spend and fuel per km against the period before, open alerts, a driver well above the usual.
  def summary(scope, cur, prev)
    now = totals(scope.where(date: cur))
    before = totals(scope.where(date: prev))
    spend_d = before[:spend].to_d.positive? ? now[:spend].to_d / before[:spend] - 1 : nil
    eff = ->(s) { s[:fuel].to_d.positive? && s[:fuel_km].to_d.positive? ? s[:fuel_km].to_d / s[:fuel] : nil }
    eff_now = eff.call(now)
    eff_before = eff.call(before)
    eff_d = eff_now && eff_before ? eff_now / eff_before - 1 : nil
    alerts = FuelAlert.open.order(date: :desc).includes(:vehicle).then { |a| @key && @view != "all" ? a.joins(:fuel_entry).where(fuel_entries: { VIEWS[@view] => @key == "none" ? nil : @key }) : a }.to_a
    heavy = driver_use(cur, prev).values.select { |d| d[:excess_pct] > 10 }.max_by { |d| d[:excess_pct] }
    pct = ->(x) { "#{(x.abs * 100).round}%" }
    text = []
    text << (now[:spend].to_d.positive? ? "Spend is S$#{format('%.2f', now[:spend])}#{if spend_d.nil? then '.' elsif spend_d.abs < 0.05 then ', about the same as before.' else ", #{spend_d.positive? ? 'up' : 'down'} #{pct.call(spend_d)} on the period before." end}" : "No fuel entries in this period.")
    if eff_now
      text << "Fuel use is #{eff_now.round(1)} km/L#{if eff_d.nil? then '.' elsif eff_d.abs < 0.05 then ", steady against #{eff_before.round(1)} before." elsif eff_d.negative? then ", #{pct.call(eff_d)} worse than #{eff_before.round(1)} before, so each km costs more fuel." else ", #{pct.call(eff_d)} better than #{eff_before.round(1)} before." end}"
    end
    text << (alerts.any? ? "#{alerts.size} #{alerts.size == 1 ? 'fill needs' : 'fills need'} a look, the latest on #{alerts.first.vehicle.plate}: #{alerts.first.message.sub(/\A./, &:downcase)}." : "No unusual fills in the last 90 days.")
    if heavy
      many = heavy[:vehicles].size > 1
      text << "#{heavy[:name]} uses #{heavy[:excess_pct]}% more fuel per km than usual for the buses driven" \
              "#{heavy[:excess_pct_before].to_i > 10 ? ', in this period and the one before' : ''}. " \
              "#{many ? "This is across #{heavy[:vehicles].size} buses, so it points to driving style (idling, hard acceleration) more than the bus." : "This is all on #{heavy[:vehicles].first}, so it could be the driver or the bus. Swap buses for a week to tell."}"
    end
    worth = alerts.any? || heavy.present? || (eff_d && eff_d < -0.1) || (spend_d && spend_d > 0.2)
    { title: worth ? "Worth a Look" : "All Normal", worth_a_look: !!worth, text: text.join(" ") }
  end

  def median(values) = values.sort[values.size / 2]
end
