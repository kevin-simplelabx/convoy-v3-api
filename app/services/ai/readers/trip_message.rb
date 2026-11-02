# Fill from Message: a trip request pasted from a WhatsApp chat, an email or a note, read into trips for the trip form.
# The prompt carries today's date, the company's Managed Clients, its Vehicle Types and the Message Terms.
module Ai
  module Readers
    class TripMessage < Base
      TYPES = %w[adhoc twoway disposal airport].freeze
      MAX_TEXT = 12_000
      MAX_TRIPS = 100
      TITLES = /\A(mr|mrs|ms|mdm|miss|dr)\.?\s+/i

      S = Ai::Schema
      reply S.object(
        is_trip: :boolean, client: :string, client_raw: :string,
        contact: S.object(name: :string, phone: :string, email: :string, org: :string),
        notes: :string,
        trips: S.array(S.object(
          type: S.enum(*TYPES), date: :string, time: :string, return_time: :string, hours: :number,
          direction: S.enum("arr", "dep"), terminal: :string, flight: :string, flight_time: :string,
          pickup: :string, stops: S.array({ type: "string" }), dropoff: :string, pax: :number, bags: :number,
          luggage: S.object(cabin: :number, medium: :number, large: :number, xl: :number, oversized: :number),
          vehicles: S.array(S.object(type: :string, n: :number)),
          guest_name: :string, guest_phone: :string, signboard: :string, label: :string,
          price: :number, price_for: S.enum("trip", "vehicle", "hour", "both"), mg_fee: :number, notes: :string
        )),
        assume: S.array({ type: "string" }), miss: S.array({ type: "string" })
      )

      def instructions
        today = Date.current
        <<~TEXT
          You read trip requests for a private bus and car hire company in Singapore. The message was pasted from a WhatsApp group chat, an email or a note. It may be informal, with Singlish, short forms and typos. Today is #{today.strftime('%A')} #{today.iso8601}.

          Fill every key: is_trip (false if the message has no trip request at all), client (the company or organisation the trip is for, spelt exactly as one name in the Clients list when it clearly is one, else ""), client_raw (the company as written), contact {name, phone, email, org} (the person asking for the trip or coordinating it), notes (anything useful for the whole booking that is not a driver instruction),
          trips (one per trip, in date and time order: type ("adhoc" one way point to point, also called transfer, drop or charter; "twoway" out and back the same day; "disposal" a vehicle hired by the hour or on standby; "airport" to or from Changi Airport or with a flight), date (YYYY-MM-DD), time (pick-up time HH:MM, 24-hour), return_time (twoway only, HH:MM), hours (disposal only), direction ("arr" when picking up at the airport after landing, "dep" when going to the airport to fly), terminal ("T1", "T2", "T3", "T4" or ""), flight (flight number such as SQ321), flight_time (landing or departure time HH:MM), pickup, stops (places between pick-up and drop-off), dropoff, pax (number of passengers), bags (total pieces of luggage if given), luggage {cabin, medium, large, xl, oversized} (counts only when sizes are given), vehicles (list of {type, n}: type is one value from the Vehicle Types list, the smallest that matches what is asked; n is how many; empty when no vehicle is mentioned), guest_name and guest_phone (the passenger to call on the day, when different from the contact), signboard (name on a meet and greet sign), label (sign shown on the bus), price (the client price quoted, a number without the currency), price_for ("trip" for the whole trip with all its vehicles, "vehicle" for each vehicle, "hour" per hour, "both" for both ways of a twoway trip together), mg_fee (a meet and greet price quoted on its own), notes (instructions for the driver, short sentences)),
          assume (short sentences on anything you inferred, such as "tmr read as Wed 21 Oct 2026" or "Half day read as 4 hours"), miss (what a booking needs that the message does not say, such as "Pick-up time" or "Drop-off").

          Rules: resolve relative dates (tmr, this Fri, next Mon) from today; dates like 21/10 are day then month; with no year use the next such date from today. Times like 8am, 0815, 8.15pm become 08:00, 08:15, 20:15. Copy places as written, fix obvious typos and expand well-known Singapore short forms and the terms listed below; keep block numbers and postal codes. A return written separately that goes back to the first pick-up the same day is one twoway trip; otherwise make separate trips. If only half day or full day is written for a disposal, use 4 or 8 hours and say so in assume. Phone numbers as digits only. Use "" or 0 for anything not in the message. Do not guess names, places or times.

          Clients:
          #{client_names.presence&.join("\n") || '(none)'}

          Vehicle Types (value = name):
          #{vehicle_types.map { |t| "#{t.key} = #{t.label}" }.join("\n")}

          Terms used in these messages (term: what it means):
          #{MessageTerm.order(:kind, :term).map { |t| "#{t.term}: #{t.means}" }.join("\n")}
        TEXT
      end

      def input(text) = "Message:\n#{text.to_s[0, MAX_TEXT]}"

      def clean(r)
        raise ApplicationService::Error, "This does not look like a trip request" if r[:is_trip] == false

        contact = (r[:contact] || {}).then { |c| { name: str(c[:name]), phone: phone(c[:phone]), email: str(c[:email]), org: str(c[:org]) }.compact }
        trips = Array(r[:trips]).filter_map { |t| clean_trip(t || {}, contact) }.first(MAX_TRIPS)
        raise ApplicationService::Error, "No trip found in the message" if trips.empty?

        raw = str(r[:client]) || str(r[:client_raw])
        client = match_client(raw)
        data = { client_id: client&.id, client_name: client&.name, client_raw: raw, contact:, notes: str(r[:notes]),
                 trips:, assume: list(r[:assume]), miss: list(r[:miss]) }
        data.merge(forms: trips.map { |t| Trips::MessageForm.new(data, t, vehicle_types).build })
      end

      private

      def client_names = @client_names ||= Client.kept.order(:name).limit(300).pluck(:name)
      def vehicle_types = @vehicle_types ||= VehicleType.enabled_for(ActsAsTenant.current_tenant).to_a

      # The client named in the message: exact name, else one name contains the other (3+ letters).
      def match_client(raw)
        return nil if raw.blank?

        down = raw.downcase
        Client.kept.find_by("LOWER(name) = ?", down) ||
          (raw.length > 2 && Client.kept.to_a.find { |c| c.name.downcase.include?(down) || down.include?(c.name.downcase) })
      end

      def clean_trip(t, contact)
        type = TYPES.include?(t[:type]) ? t[:type] : "adhoc"
        luggage = (t[:luggage] || {}).to_h.transform_values { |v| v.to_f.round }.select { |_, v| v.positive? }.symbolize_keys
        keys = vehicle_types.map(&:key)
        vehicles = Array(t[:vehicles]).filter_map do |v|
          { type: v[:type].to_s, n: [ v[:n].to_f.round, 1 ].max } if keys.include?(v[:type].to_s)
        end.first(10)
        trip = {
          type:, date: date(t[:date]), time: time(t[:time]), return_time: time(t[:return_time]), hours: positive(t[:hours]),
          direction: t[:direction] == "dep" ? "dep" : "arr", terminal: t[:terminal].to_s.upcase[/\AT[1-4]\z/],
          flight: str(t[:flight])&.upcase&.delete(" "), flight_time: time(t[:flight_time]), pickup: str(t[:pickup]),
          stops: Array(t[:stops]).filter_map { |s| str(s) }.first(5), dropoff: str(t[:dropoff]),
          pax: positive(t[:pax])&.round, bags: positive(t[:bags])&.round, luggage:, vehicles:,
          guest_name: str(t[:guest_name]), guest_phone: phone(t[:guest_phone]), signboard: str(t[:signboard]),
          label: str(t[:label]), price: positive(t[:price])&.round(2),
          price_for: %w[trip vehicle hour both].include?(t[:price_for]) ? t[:price_for] : "trip",
          mg_fee: positive(t[:mg_fee])&.round(2), notes: str(t[:notes])
        }
        drop_guest_who_is_contact(trip, contact)
        trip.values_at(:pickup, :dropoff, :time, :date, :flight).any? ? trip : nil
      end

      # A guest who is the contact again (same name or phone) is dropped, so the form keeps Guest same as requestor.
      def drop_guest_who_is_contact(trip, contact)
        same_name = trip[:guest_name] && contact[:name] &&
                    trip[:guest_name].downcase.sub(TITLES, "") == contact[:name].downcase.sub(TITLES, "")
        same_phone = trip[:guest_phone] && trip[:guest_phone] == contact[:phone]
        trip.merge!(guest_name: nil, guest_phone: nil) if same_name || same_phone
      end

      def positive(v)
        n = v.to_f
        n.positive? ? n : nil
      end

      def list(v) = Array(v).filter_map { |x| str(x) }.first(12)
    end
  end
end
