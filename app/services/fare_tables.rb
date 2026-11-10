# School Bus Bus Fares: billing periods of a year and the fare table maths (port of logic/fares.js).
module FareTables
  MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

  module_function

  # Billing periods of a year: one per term, or one per chosen month of the year (in year order), each with its school
  # days and CCA days — from the snapshot once the fare table is locked.
  def periods(year, table = year.fare_table, cycle: table&.cycle, months: table&.months)
    list = cycle == "month" ? month_periods(year, months) : term_periods(year)
    snap = table&.period_snapshot
    return list unless table&.locked? && snap.is_a?(Array) && snap.size == list.size

    list.each_with_index.map { |p, i| p.merge(school_days: snap[i][0], cca_days: snap[i][1]) }
  end

  def term_periods(year)
    year.terms.map do |t|
      cca_from, cca_to = year.cca_same_as_terms ? [ t.starts_on, t.ends_on ] : [ t.cca_starts_on, t.cca_ends_on ]
      { label: "#{year.period_label} #{t.position}", short: "#{year.structure == 'semester' ? 'Sem' : 'Term'} #{t.position}",
        starts_on: t.starts_on, ends_on: t.ends_on, school_days: year.school_days_between(t.starts_on, t.ends_on),
        cca_days: year.school_days_between(cca_from, cca_to) }
    end
  end

  # The month each bill is raised in: the chosen months, or the month each term starts.
  def bill_months(year, table)
    periods(year, table).map { it[:starts_on]&.beginning_of_month }
  end

  # A bill amount with the Extra Charges of its month: base + every % on the base + every amount (one-offs apart).
  def adjusted(base, month, target, adjustments)
    on = adjustments.select { it.kind != "once" && it.applies?(month, target) }
    (base + on.sum(0.to_d) { it.kind == "pct" ? base * it.value / 100 : it.value }).round(2)
  end

  def one_offs(month, target, adjustments) = adjustments.select { it.kind == "once" && it.applies?(month, target) }.sum(0.to_d, &:value)

  # Money as Bus Fares sends it: a string with 2 decimals ("420.00"); nil stays nil. `money_tree` does every decimal
  # of the worked-out fares (they hold only money).
  def money(v) = v && format("%.2f", v)

  def money_tree(x)
    case x
    when BigDecimal then money(x)
    when Hash then x.transform_values { money_tree(it) }
    when Array then x.map { money_tree(it) }
    else x
    end
  end

  def month_periods(year, months)
    (0..11).filter_map do |i|
      first = year.starts_on >> i
      next unless Array(months).include?(first.month)

      days = (first..first.end_of_month).count { year.school_day?(it) }
      { label: "#{MONTHS[first.month - 1]} #{first.year}", short: MONTHS[first.month - 1], starts_on: first, ends_on: first.end_of_month,
        school_days: days, cca_days: days }
    end
  end
end
