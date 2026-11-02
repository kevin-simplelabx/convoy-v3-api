# A Singapore vehicle loan / hire purchase instalment schedule (Vehicle Financials > upload the lender's schedule).
module Ai
  module Readers
    class VehicleLoanSchedule < Base
      ask <<~TEXT
        This should be a vehicle loan or hire purchase instalment schedule from a Singapore finance company (it may be a
        scanned image, read the text in it). Fill every key: is_schedule (true or false), plate (vehicle registration no.,
        uppercase, no spaces), lender (finance company name), account_number (account or agreement number), bought_on
        (purchase or agreement date), loan_amount, rate (interest rate in percent per year), term_charge (total term charge
        or interest), tenure_months (number of monthly instalments), first_instalment, monthly_instalment, last_instalment,
        first_due_on (due date of instalment 1), make, model, chassis_number, engine_number, registered_on (original
        registration date), paid (instalments already shown as paid: [{ n, paid_on }]). Amounts as plain numbers like
        1234.50. Write every date as YYYY-MM-DD. Use an empty string for anything not shown. Do not guess.
      TEXT
      reply Ai::Schema.object(
        is_schedule: :boolean, plate: :string, lender: :string, account_number: :string, bought_on: :string, loan_amount: :string,
        rate: :string, term_charge: :string, tenure_months: :string, first_instalment: :string, monthly_instalment: :string,
        last_instalment: :string, first_due_on: :string, make: :string, model: :string, chassis_number: :string, engine_number: :string,
        registered_on: :string, paid: Ai::Schema.array(Ai::Schema.object(n: :string, paid_on: :string))
      )
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like a loan schedule" if r[:is_schedule] == false

        {
          plate: plate(r[:plate]), lender: str(r[:lender]), account_number: str(r[:account_number]), bought_on: date(r[:bought_on]),
          loan_amount: number(r[:loan_amount]), rate: number(r[:rate]), term_charge: number(r[:term_charge]),
          tenure_months: number(r[:tenure_months])&.to_i, first_instalment: number(r[:first_instalment]),
          monthly_instalment: number(r[:monthly_instalment]), last_instalment: number(r[:last_instalment]),
          first_due_on: date(r[:first_due_on]), make: str(r[:make]), model: str(r[:model]), chassis_number: str(r[:chassis_number]),
          engine_number: str(r[:engine_number]), registered_on: date(r[:registered_on]),
          paid: Array(r[:paid]).filter_map { |p| (n = p[:n].to_i).positive? ? { n:, paid_on: date(p[:paid_on]) } : nil }
        }.compact
      end
    end
  end
end
