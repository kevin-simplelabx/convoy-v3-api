# A pump or charging receipt (Fuel & Energy): kind, company, station, date, time, quantity, price, total, plate, odometer.
module Ai
  module Readers
    class FuelReceipt < Base
      KINDS = %w[diesel petrol def elec].freeze

      ask <<~TEXT
        This should be a Singapore fuel station receipt (diesel, petrol or AdBlue/DEF) or an EV charging receipt. It may be a
        photo. Fill every key: is_receipt (true or false), kind (diesel, petrol, def or elec; def is AdBlue), brand (the fuel or
        charging company only, e.g. Esso, Shell, SPC, Caltex, Sinopec, SP Mobility, Charge+), station (the branch or location
        without the company name, e.g. Jurong West Ave 2), date (YYYY-MM-DD), time (HH:MM, 24-hour), quantity (litres or kWh, a
        plain number), price (per litre or kWh), cost (total paid), plate (vehicle number if printed, uppercase, no spaces),
        odometer (if printed, digits only). Use an empty string for anything not shown. Do not guess.
      TEXT
      reply Ai::Schema.object(
        is_receipt: :boolean, kind: Ai::Schema.enum(*KINDS, ""), brand: :string, station: :string, date: :string, time: :string,
        quantity: :string, price: :string, cost: :string, plate: :string, odometer: :string
      )
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like a fuel or charging receipt" if r[:is_receipt] == false

        quantity = number(r[:quantity])
        price = number(r[:price])
        cost = number(r[:cost]) || (quantity && price && (quantity.to_d * price.to_d).round(2).to_s)
        { kind: KINDS.include?(r[:kind]) ? r[:kind] : nil, brand: str(r[:brand]), station: str(r[:station]), date: date(r[:date]),
          time: time(r[:time]), quantity:, cost:, plate: plate(r[:plate]), odometer: integer(r[:odometer]) }.compact
      end
    end
  end
end
