# A workshop invoice (servicing, repairs or tyres): workshop, address, date, plate, odometer, GST and line items.
module Ai
  module Readers
    class MaintenanceInvoice < Base
      TYPES = %w[part tyre labour other].freeze
      POSITIONS = [ "Front Left", "Front Right", "Rear Left Outer", "Rear Left Inner", "Rear Right Inner", "Rear Right Outer", "Spare", "" ].freeze

      ask <<~TEXT
        This should be a vehicle workshop invoice from Singapore (servicing, repairs or tyres for a bus). It may be a photo.
        Fill every key: is_invoice (true or false), workshop (company name), address, date (YYYY-MM-DD), plate (vehicle number,
        uppercase, no spaces), odometer (odometer or mileage, digits only), gst (true when GST is charged), lines (each with
        type: part, tyre, labour or other; description; part_number; brand; model; tyre_position: for tyres one of Front Left,
        Front Right, Rear Left Outer, Rear Left Inner, Rear Right Inner, Rear Right Outer, Spare, else ""; quantity; unit_price:
        price per unit before GST, a plain number). Use an empty string for anything not shown. Do not guess.
      TEXT
      reply Ai::Schema.object(
        is_invoice: :boolean, workshop: :string, address: :string, date: :string, plate: :string, odometer: :string, gst: :boolean,
        lines: Ai::Schema.array(Ai::Schema.object(type: Ai::Schema.enum(*TYPES), description: :string, part_number: :string,
                                                  brand: :string, model: :string, tyre_position: Ai::Schema.enum(*POSITIONS),
                                                  quantity: :string, unit_price: :string))
      )
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like a workshop invoice" if r[:is_invoice] == false

        lines = Array(r[:lines]).map do |l|
          { line_type: TYPES.include?(l[:type]) ? l[:type] : "other", description: str(l[:description]), part_number: str(l[:part_number]),
            brand: str(l[:brand]), model: str(l[:model]), tyre_position: str(l[:tyre_position]),
            quantity: number(l[:quantity]) || "1.0", unit_price: number(l[:unit_price]) || "0.0" }.compact
        end
        { workshop: str(r[:workshop]), address: str(r[:address]), date: date(r[:date]), plate: plate(r[:plate]),
          odometer: integer(r[:odometer]), gst: r[:gst], lines: }.compact
      end
    end
  end
end
