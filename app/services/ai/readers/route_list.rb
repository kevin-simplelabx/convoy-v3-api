# Import Route List (School Run): a contractor's route list (PDF, Excel, photo or CSV) read into the route, the school,
# times, driver notes and one row per child in file order. Bus columns (plate, driver, PM bus) are ignored.
module Ai
  module Readers
    class RouteList < Base
      S = Ai::Schema
      ask <<~TEXT
        This should be a school bus route list from a transport contractor in Singapore. Read it and fill every key:
        is_route_list (true or false), label (the route label as written, e.g. AM 13 or PM1), session ("am" for a morning trip
        to school, "pm" for an afternoon trip from school), school (school name), school_address (school address with postal
        code if shown), start_date (YYYY-MM-DD), arrive_by (time the bus must reach the school, HH:MM), leave_by (time the bus
        leaves the school, HH:MM), notes (instructions for the driver or bus attendant, such as where the attendant gets off,
        as short sentences), rows (one per child, in the order of the list: name, class_name (grade or class), address (as
        written), postal (6 digits), time (HH:MM, 24-hour), point (pick-up or drop-off point or remark, e.g. Blk 443A Shelter),
        parent_name, phone (first parent phone, digits only), phone2 (second parent phone, digits only), note (other comments
        for this child)). Skip empty rows. Ignore the driver, driver phone, vehicle plate, subcontractor, PM bus and any other
        bus columns. Convert times like 6.22am to 06:22 and 17.10 to 17:10. Use an empty string for anything not shown. Do not guess.
      TEXT
      reply S.object(
        is_route_list: :boolean, label: :string, session: S.enum("am", "pm", ""), school: :string, school_address: :string,
        start_date: :string, arrive_by: :string, leave_by: :string, notes: :string,
        rows: S.array(S.object(name: :string, class_name: :string, address: :string, postal: :string, time: :string, point: :string,
                               parent_name: :string, phone: :string, phone2: :string, note: :string))
      )
      thinking :low

      def clean(r)
        raise ApplicationService::Error, "This does not look like a route list" if r[:is_route_list] == false

        rows = Array(r[:rows]).filter_map do |x|
          name = str(x[:name]) or next
          { name:, class_name: str(x[:class_name]), address: str(x[:address]), postal: x[:postal].to_s[/\d{6}/], time: time(x[:time]),
            point: str(x[:point]), parent_name: str(x[:parent_name]), phone: phone(x[:phone]), phone2: phone(x[:phone2]), note: str(x[:note]) }
        end
        raise ApplicationService::Error, "No students found in the list" if rows.empty?

        { label: str(r[:label]), session: r[:session] == "pm" ? "pm" : "am", school: str(r[:school]), school_address: str(r[:school_address]),
          start_date: date(r[:start_date]), arrive_by: time(r[:arrive_by]), leave_by: time(r[:leave_by]), notes: str(r[:notes]), rows: }
      end
    end
  end
end
