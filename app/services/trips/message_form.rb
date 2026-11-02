# Turns one trip read from a message into trip form params (the names POST /trips takes) with the labels filled
# and notes on how the quoted price was read. The front end fills its form from it; nothing is saved here.
module Trips
  class MessageForm
    KINDS = { "adhoc" => "ad_hoc", "twoway" => "ad_hoc", "disposal" => "disposal", "airport" => "airport_transfer" }.freeze
    LUGGAGE = { cabin: :luggage_cabin, medium: :luggage_medium, large: :luggage_large, xl: :luggage_extra_large, oversized: :luggage_oversized }.freeze

    def initialize(data, trip, vehicle_types)
      @data = data
      @t = trip
      @types = vehicle_types.index_by(&:key)
      @filled = []
      @notes = []
    end

    def build
      a = { kind: KINDS.fetch(@t[:type]) }
      fill(:trip_type) { true }
      fill(:client) { a[:client_id] = @data[:client_id] }
      fill(:date) { a[:starts_on] = @t[:date] }
      fill(:time) { a[:start_time] = @t[:time] || (airport? ? @t[:flight_time] : nil) }
      fill(:hours) { a[:hours] = @t[:hours] } if disposal?
      airport(a) if airport?
      route(a)
      fill(:passengers) { a[:pax] = @t[:pax] }
      luggage(a)
      vehicles(a)
      people(a)
      fill(:trip_label) { a[:label] = @t[:label] }
      price(a)
      notes(a)
      { trip: a.compact, return_trip: return_trip(a), filled: @filled, notes: @notes }
    end

    private

    def airport? = @t[:type] == "airport"
    def disposal? = @t[:type] == "disposal"
    def two_way? = @t[:type] == "twoway"
    def vehicle_count = @t[:vehicles].sum { |v| v[:n] }

    # Run the block; a truthy value records the label as filled.
    def fill(label)
      @filled << label.to_s if yield.present?
    end

    def airport(a)
      a[:airport_direction] = @t[:direction] == "dep" ? "departure" : "arrival"
      a[:terminal] = @t[:terminal]
      a[:flight_time] = @t[:flight_time]
      fill(:flight) { a[:flight_number] = @t[:flight] }
      fill(:signboard) { a[:meet_and_greet] = true if (a[:signboard_name] = @t[:signboard]) }
    end

    def airport_name = [ "Changi Airport", @t[:terminal] ].compact.join(" ")

    def points
      pickup = airport? && @t[:direction] == "arr" ? airport_name : @t[:pickup]
      dropoff = airport? && @t[:direction] == "dep" ? airport_name : @t[:dropoff]
      [ pickup, *@t[:stops], (dropoff unless disposal? && dropoff.blank?) ].compact_blank
    end

    def stops_for(names)
      names.each_with_index.map do |name, i|
        { position: i, name:, use: i.zero? ? "pu" : (i == names.size - 1 ? "do" : "both") }
      end
    end

    def route(a)
      fill(:route) { a[:stops_attributes] = stops_for(points).presence }
    end

    def luggage(a)
      if @t[:luggage].present?
        a[:luggage_on] = true
        @t[:luggage].each { |size, n| a[LUGGAGE[size.to_sym]] = n if LUGGAGE[size.to_sym] }
        @filled << "luggage"
      end
    end

    def vehicles(a)
      return if @t[:vehicles].empty?

      a[:vehicle_requirements_attributes] = @t[:vehicles].map { |v| { vehicle_type_id: @types[v[:type]].id, count: v[:n] } }
      a[:vehicles_count] = vehicle_count
      @filled << "vehicles"
    end

    def people(a)
      c = @data[:contact] || {}
      fill(:requestor) do
        a.merge!(requestor_name: c[:name], requestor_phone: c[:phone], requestor_email: c[:email])
        c.slice(:name, :phone, :email).values.any?
      end
      fill(:guest) do
        a.merge!(guest_is_requestor: false, guest_name: @t[:guest_name], guest_phone: @t[:guest_phone]) if @t[:guest_name] || @t[:guest_phone]
      end
    end

    # Client price: per hour for Disposal, per way for a two-way trip, whole route or each vehicle for 2+ vehicles.
    def price(a)
      quoted = @t[:price] or return mg_fee(a)

      if disposal?
        a[:hourly_rate] = true
        if @t[:price_for] != "hour" && @t[:hours]
          a[:price] = (quoted / @t[:hours]).round(2)
          @notes << "#{money(quoted)} for #{@t[:hours]} h read as #{money(a[:price])} an hour"
        else
          a[:price] = quoted
        end
      elsif two_way? && @t[:price_for] == "both"
        a[:price] = (quoted / 2).round(2)
        @notes << "#{money(quoted)} for both ways read as #{money(a[:price])} each way"
      elsif vehicle_count > 1
        a[:price_per] = @t[:price_for] == "vehicle" ? "vehicle" : "route"
        a[:price_set] = "same"
        a[:price] = quoted
        @notes << (a[:price_per] == "vehicle" ? "#{money(quoted)} for each vehicle" : "#{money(quoted)} for the whole route, all #{vehicle_count} vehicles")
      else
        a[:price] = quoted
      end
      @filled << "client_price"
      mg_fee(a)
    end

    def mg_fee(a)
      return unless airport? && @t[:direction] == "arr" && @t[:mg_fee]

      a[:meet_and_greet] = true
      a[:meet_and_greet_fee] = @t[:mg_fee]
      @filled << "meet_and_greet_fee"
    end

    def notes(a)
      bags = @t[:bags] && @t[:luggage].blank? ? "#{@t[:bags]} pieces of luggage" : nil
      fill(:notes) { a[:notes] = [ @t[:notes], bags, @data[:notes] ].compact_blank.join("\n").presence }
    end

    # Two-way: the return starts at the return time and goes back the same way.
    def return_trip(a)
      return nil unless two_way?

      @filled << "return_time" if @t[:return_time]
      { start_time: @t[:return_time], stops_attributes: stops_for(points.reverse).presence }.compact
    end

    def money(v) = format("S$%.2f", v)
  end
end
