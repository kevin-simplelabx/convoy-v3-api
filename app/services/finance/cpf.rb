# Singapore CPF employer contribution for a month's wage (port of logic/cpf.js): Citizens and PRs only; the rate by age
# band (moves the month after the 55th / 60th / 65th / 70th birthday), on the wage up to the Ordinary Wage ceiling.
module Finance
  module Cpf
    module_function

    TABLES = [ { from: Date.new(2025, 1, 1), rates: [ 17, 15.5, 12, 9, 7.5 ], ceiling: 7400 },
               { from: Date.new(2026, 1, 1), rates: [ 17, 16, 12.5, 9, 7.5 ], ceiling: 8000 } ].freeze

    # { rate, amount } for a wage in the month (Date, first day). residential_status nil counts as Citizen / PR.
    def employer(wage, date_of_birth, month, residential_status)
      return { rate: 0, amount: 0.to_d } if residential_status.present? && !residential_status.to_s.match?(/citizen|permanent/i)

      wage = [ wage.to_d, 0 ].max
      return { rate: 0, amount: 0.to_d } if wage <= 50

      table = TABLES.select { |t| t[:from] <= month }.last || TABLES.first
      rate = table[:rates][band(date_of_birth, month)]
      { rate:, amount: ([ wage, table[:ceiling] ].min * rate / 100).round(2) }
    end

    def band(dob, month)
      return 0 unless dob

      [ 55, 60, 65, 70 ].count { |age| month > (dob >> (age * 12)).end_of_month }
    end
  end
end
