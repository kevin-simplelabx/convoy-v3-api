# Fleet > Maintenance: the visit list by tab (upcoming, to_record, completed, cancelled) with search and vehicle filter,
# the tab counts, the KPI tiles and the last 12 months of spend (by type, vehicle, workshop, month) and tyre changes.
# Amounts include GST when the visit has it (line price × quantity × (1 + rate)), as the page shows them.
class MaintenancePage
  TABS = %w[upcoming to_record completed cancelled].freeze
  LINE_TYPES = { "part" => "Parts", "tyre" => "Tyres", "labour" => "Labour", "other" => "Other" }.freeze
  LINE_AMOUNT = <<~SQL.squish.freeze
    maintenance_lines.quantity * maintenance_lines.unit_price
      * CASE WHEN maintenance_visits.gst_on THEN 1 + maintenance_visits.gst_rate / 100 ELSE 1 END
  SQL
  TOP = 8

  def initialize(scope, params, today: Date.current)
    @scope = scope
    @params = params
    @today = today
  end

  # Visits of the tab, searched and filtered; Upcoming and To Record soonest first, the others newest first.
  def list
    tab = TABS.include?(@params[:tab]) ? @params[:tab] : "upcoming"
    s = in_tab(filtered(@scope), tab)
    tab.in?(%w[upcoming to_record]) ? s.order(:date, :start_time) : s.order(date: :desc, start_time: :desc)
  end

  def counts = TABS.index_with { |t| in_tab(filtered(@scope), t).count }

  def kpis
    month = completed.where(date: @today.beginning_of_month..@today.end_of_month)
    year = completed.where(date: year_start..@today)
    { next_30_days: @scope.scheduled.where(date: @today..(@today + 30)).count,
      to_record: @scope.scheduled.where(date: ...@today).count,
      spend_this_month: amount(month), last_12_months: amount(year), last_12_months_visits: year.count }
  end

  # Spend, last 12 months (vehicle filter applies): by line type, vehicle and workshop (top 8, with % of the total),
  # by month, and every tyre changed.
  def spend
    lines = MaintenanceLine.joins(:visit).merge(completed_in_year)
    total = lines.sum(Arel.sql(LINE_AMOUNT)).to_d.round(2)
    {
      total:,
      by_type: bars(lines.group(:line_type).sum(Arel.sql(LINE_AMOUNT)).transform_keys { |k| LINE_TYPES[k] }, total),
      by_vehicle: bars(lines.joins(visit: :vehicle).group("vehicles.plate").sum(Arel.sql(LINE_AMOUNT)), total),
      by_workshop: bars(lines.left_joins(visit: :workshop).group("workshops.name").sum(Arel.sql(LINE_AMOUNT))
                             .transform_keys { |k| k || "Workshop not set" }, total),
      by_month: lines.group_by_month("maintenance_visits.date", range: year_start..@today, format: "%Y-%m")
                     .sum(Arel.sql(LINE_AMOUNT)).transform_values { |v| v.to_d.round(2) },
      tyres: tyres(lines)
    }
  end

  private

  def year_start = (@today << 11).beginning_of_month

  def completed = @scope.completed
  def completed_in_year = filtered(completed).where(date: year_start..@today)

  def amount(visits)
    MaintenanceLine.joins(:visit).merge(visits).sum(Arel.sql(LINE_AMOUNT)).to_d.round(2)
  end

  def filtered(scope)
    scope = scope.where(vehicle_id: @params[:vehicle_id]) if @params[:vehicle_id].present?
    return scope if @params[:q].blank?

    like = "%#{MaintenanceVisit.sanitize_sql_like(@params[:q].to_s.strip)}%"
    kinds = MaintenanceVisit::KINDS.select { |_, name| name.downcase.include?(@params[:q].to_s.strip.downcase) }.keys
    scope.left_joins(:vehicle, :workshop)
         .where("vehicles.plate ILIKE :q OR workshops.name ILIKE :q OR maintenance_visits.work_to_do ILIKE :q OR maintenance_visits.kind IN (:kinds)",
                q: like, kinds: kinds.presence || [ "" ])
  end

  def in_tab(scope, tab)
    case tab
    when "upcoming" then scope.scheduled.where(date: @today..)
    when "to_record" then scope.scheduled.where(date: ...@today)
    when "completed" then scope.completed
    else scope.cancelled
    end
  end

  def bars(sums, total)
    sums.sort_by { |_, v| -v }.first(TOP).map do |name, v|
      { name:, amount: v.round(2), pct: total.positive? ? (v / total * 100).round : 0 }
    end
  end

  # Each tyre line: when, which bus, position, brand and model, size (description), odometer, cost each, workshop.
  def tyres(lines)
    lines.tyre.joins(visit: :vehicle).left_joins(visit: :workshop).order("maintenance_visits.date DESC")
         .pluck("maintenance_visits.date", "vehicles.plate", :tyre_position, :brand, :model, :description,
                "maintenance_visits.odometer", :quantity, Arel.sql(LINE_AMOUNT), "workshops.name")
         .map do |date, plate, position, brand, model, size, odometer, qty, amount, workshop|
           { date:, plate:, position:, tyre: [ brand, model ].compact_blank.join(" ").presence, size:, odometer:,
             quantity: qty, cost_each: (amount / (qty.to_d.nonzero? || 1)).round(2), workshop: }
         end
  end
end
