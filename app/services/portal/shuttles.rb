# Client Portal › Shuttles (read only; "To change a timing or a stop, call or email them"): the client's corporate
# shuttle routes by site (a route serving several sites shows under each; routes with no site under Other Routes, for
# people covering every site), with days, dates, status, tags, the runs of each direction and the full timetable.
module Portal
  class Shuttles < ApplicationService
    DIRECTIONS = { 1 => "Morning", 2 => "Evening" }.freeze

    def initialize(client_user:, today: Date.current)
      @user = client_user
      @client = client_user.client
      @today = today
    end

    def call
      routes = Trip.kept.where(client: @client, kind: "corporate_shuttle").includes(:client_site, stops: :client_site, runs: :times)
                   .order(:title).map { route(it) }
      sites = @user.limit_to_sites(@client.sites, :id).order(:name).to_a
      groups = sites.filter_map do |s|
        list = routes.select { |r| r[:sites].any? { it[:id] == s.id } }
        { site: { id: s.id, name: s.name }, routes: list } if list.any?
      end
      other = routes.select { it[:sites].empty? }
      groups << { site: nil, routes: other } if other.any? && @user.all_sites?
      groups
    end

    def self.days_text(days) = TripDecorator.days_text(days)

    private

    def route(t)
      sites = ([ t.client_site ] + t.stops.map(&:client_site)).compact.uniq
      { id: t.id, title: t.title, label: t.label, days: t.days, days_text: self.class.days_text(t.days), skip_public_holidays: t.skip_public_holidays,
        starts_on: t.starts_on, ends_on: t.ends_on, status: status(t), cross_site: sites.size > 1, tags: t.route_tags,
        sites: sites.map { { id: it.id, name: it.name } }, directions: [ 1, 2 ].filter_map { direction(t, it) } }
    end

    def status(t)
      return "ended" if t.ends_on && t.ends_on < @today
      return "starts" if t.starts_on > @today

      "active"
    end

    def direction(t, dir)
      stops = t.stops.select { it.direction == dir }.sort_by(&:position)
      runs = t.runs.select { it.direction == dir }.sort_by(&:position)
      return if stops.empty? || runs.empty?

      { direction: dir, name: DIRECTIONS[dir],
        stops: stops.map { { id: it.id, name: it.name, site: it.client_site && { id: it.client_site.id, name: it.client_site.name } } },
        runs: runs.map do |r|
          by_stop = r.times.to_h { [ it.trip_stop_id, it.time ] }
          { id: r.id, start_time: r.start_time_hm, end_time: r.end_time_hm, times: stops.map { Clock.hm(by_stop[it.id]) } }
        end }
    end
  end
end
