# A row of Trips Using This Calendar: { trip:, runs_skipped:, skipped: } from Calendars::TripsUsing.
class CalendarTripBlueprint < Blueprinter::Base
  field(:id) { |row| row[:trip].id }
  field(:title) { |row| row[:trip].title }
  field(:kind) { |row| row[:trip].kind }
  field(:kind_name) { |row| row[:trip].kind_name }
  field(:client_name) { |row| row[:trip].client&.name }
  field(:repeat_text) { |row| row[:trip].repeat_text }
  field(:start_time) { |row| row[:trip].start_time_hm }
  field(:starts_on) { |row| row[:trip].starts_on }
  field(:ends_on) { |row| row[:trip].last_date }
  field(:runs_skipped) { |row| row[:runs_skipped] }
  field(:skipped) { |row| row[:skipped] }
end
