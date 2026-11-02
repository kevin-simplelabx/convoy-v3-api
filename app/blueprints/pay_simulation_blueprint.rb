# Salary Simulator / Earnings breakdown of Pay::Month: { result:, holidays: }.
class PaySimulationBlueprint < Blueprinter::Base
  # Pay this month: the scheme pay plus bonuses paid now (total_with_bonuses); `total` is the scheme pay only.
  field(:total) { |x| x[:result].total.round(2) }
  field(:total_with_bonuses) { |x| (x[:result].total + Array(x[:bonuses]).select { |b| b[:paid_now] }.sum { |b| b[:amount] + b[:adjust].to_d }).round(2) }
  field(:trips) { |x| x[:result].trips }
  field(:parts) do |x|
    x[:result].parts.map do |p|
      { from: p.from, to: p.to, scheme: p.scheme && { id: p.scheme.id, name: p.scheme.name }, total: p.total.round(2),
        amounts: p.parts, rows: p.rows, weeks: p.weeks, penalty: p.penalty }
    end
  end
  field(:days) do |x|
    x[:result].parts.flat_map { |p| p.days.to_a }.to_h do |date, d|
      [ date.iso8601, d.merge(holiday: x[:holidays][date], lines: d[:lines].map { |l| l.except(:ref) }) ]
    end
  end
  field(:bonuses) { |x| x[:bonuses] || [] }
end
