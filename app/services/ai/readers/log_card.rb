# Singapore LTA vehicle log card: plate, make, model, year, registration, chassis, engine, COE and road tax expiry, seats.
module Ai
  module Readers
    class LogCard < Base
      FIELDS = %i[plate make model year_made registered_on chassis_number engine_number coe_expires_on road_tax_expires_on seats].freeze

      ask <<~TEXT
        This should be a Singapore LTA vehicle log card (vehicle registration details). Read it and fill every key:
        is_log_card (true or false), plate (Vehicle No., uppercase, no spaces), make, model, year_made (year of manufacture, 4 digits),
        registered_on (original registration date), chassis_number, engine_number, coe_expires_on (COE expiry date),
        road_tax_expires_on (road tax expiry date), seats (passenger seating capacity, excluding the driver, digits only).
        Write every date as YYYY-MM-DD. Use an empty string for anything not shown. Do not guess.
      TEXT
      reply Ai::Schema.object(is_log_card: :boolean, plate: :string, make: :string, model: :string, year_made: :string,
                              registered_on: :string, chassis_number: :string, engine_number: :string,
                              coe_expires_on: :string, road_tax_expires_on: :string, seats: :string)
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like a log card" if r[:is_log_card] == false

        {
          plate: plate(r[:plate]), make: str(r[:make]), model: str(r[:model]), year_made: integer(r[:year_made]),
          registered_on: date(r[:registered_on]), chassis_number: str(r[:chassis_number])&.upcase,
          engine_number: str(r[:engine_number])&.upcase, coe_expires_on: date(r[:coe_expires_on]),
          road_tax_expires_on: date(r[:road_tax_expires_on]), seats: integer(r[:seats])
        }.compact
      end
    end
  end
end
