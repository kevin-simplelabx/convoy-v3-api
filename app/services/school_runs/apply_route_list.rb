# Apply From (Import Route List onto a saved School Run): the current list is kept as an Earlier List until the day
# before, then the stops and students are replaced by the reviewed ones. Students already on the trip keep their key,
# so their attendance history follows them.
module SchoolRuns
  class ApplyRouteList < ApplicationService
    def initialize(trip:, review:, apply_from:, user:, file_name: nil)
      @trip = trip
      @review = review
      @from = apply_from
      @user = user
      @name = file_name
    end

    def call
      Trip.transaction do
        RouteListVersion.archive!(@trip, @from) if @trip.outbound_stops.any? { |s| s.students.any? }
        keys = @trip.outbound_stops.flat_map(&:students).to_h { |s| [ s.name.downcase, s.key ] }
        attrs = @review[:trip_attributes].slice(:session, :notes).compact
        attrs[:stops_attributes] = @trip.stops.map { |s| { id: s.id, _destroy: true } } +
                                   @review[:trip_attributes][:stops_attributes].map { |s| with_keys(s, keys) }
        attrs[:route_list_name] = @name
        attrs[:route_list_imported_at] = Time.current
        Trips::Save.call(trip: @trip, attributes: attrs, user: @user)
        @trip
      end
    end

    private

    def with_keys(stop, keys)
      stop.merge(students_attributes: stop[:students_attributes].map { |st| st.merge(key: keys[st[:name].downcase]).compact })
    end
  end
end
