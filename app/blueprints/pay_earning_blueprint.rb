# HR > Earnings: a driver's month (Pay::DriverMonth::Out). List view = the row; :detail adds runs and the breakdown.
class PayEarningBlueprint < Blueprinter::Base
  field(:driver_id) { |o| o.driver.id }
  field(:name) { |o| o.driver.name }
  field(:month) { |o| o.month.strftime("%Y-%m") }
  field(:total) { |o| (o.confirmed ? o.confirmed.total : o.total).round(2) }
  field(:completed) { |o| o.runs.count { |r| r.status == "completed" } }
  field(:held) { |o| o.runs.count { |r| r.status == "issue" } }
  field(:vehicle) { |o, opts| opts[:vehicles]&.dig(o.driver.id)&.then { |v| { id: v.id, plate: v.plate } } }
  # confirmed | held | to_confirm | open
  field(:status) do |o|
    if o.confirmed then "confirmed"
    elsif o.runs.any? { |r| r.status == "issue" } then "held"
    elsif o.month.next_month <= Date.current then "to_confirm"
    else "open"
    end
  end
  field(:confirmed) { |o| o.confirmed && { by: o.confirmed.confirmed_by&.shown_name, at: o.confirmed.confirmed_at, total: o.confirmed.total } }

  view :detail do
    field(:schemes) { |o| o.result.parts.filter_map { |p| p.scheme && { from: p.from, to: p.to, id: p.scheme.id, name: p.scheme.name, rate_plan: p.scheme.rate_plan&.name } } }
    field(:counts) { |o| %w[completed issue cancelled upcoming running].index_with { |s| o.runs.count { |r| r.status == s } } }
    field(:can_confirm) { |o| Pay::ConfirmMonth.blocker(o).nil? }
    field(:why) { |o| Pay::ConfirmMonth.blocker(o) unless o.confirmed }
    field(:breakdown) do |o|
      if o.confirmed
        o.confirmed.lines.group_by { |l| [ l.part_from, l.part_to, l.scheme_name ] }.map do |(from, to, name), lines|
          { from:, to:, scheme: name, rows: lines.map { |l| { label: l.label, amount: l.amount, text: l.text }.compact } }
        end
      else
        o.result.parts.map { |p| { from: p.from, to: p.to, scheme: p.scheme&.name, amounts: p.parts, rows: p.rows, weeks: p.weeks } }
      end
    end
    field(:bonuses) { |o| o.confirmed ? [] : o.bonuses }
    field(:runs) do |o|
      frozen = o.confirmed&.runs&.index_by(&:occurrence_id) || {}
      o.runs.map do |r|
        occ = r.occurrence
        { id: occ.id, date: occ.date, start_time: Clock.hm(occ.start_time), end_time: Clock.hm(occ.end_time), trip_id: occ.trip_id,
          trip_label: occ.trip_label, kind: occ.kind, plate: occ.vehicle&.plate, trip_value: r.hours ? nil : occ.trip_value, hours: r.hours,
          status: r.status, issue: occ.issue_raised_at && { reason: occ.issue_reason, at: occ.issue_raised_at },
          amount: r.status == "completed" ? (frozen[occ.id]&.amount || o.result.job_pay[occ.id]) : nil }
      end
    end
  end
end
