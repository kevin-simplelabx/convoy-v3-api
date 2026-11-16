# Convoy App › Shuttles, the staff rider side of a Managed Client's corporate shuttle. A person reaches an employer only
# through an accepted, not paused client_riders link (the work email matched the client's domain and is verified within
# 12 months). Everything about the employer's routes is read inside that link's company and its time zone (`within`), so
# "today" is the company's today. Routes are the client's corporate_shuttle trips; runs are the resolved trip_occurrences
# (no virtual runs: beyond the 120-day horizon there is nothing to show).
module ConvoyApp
  module Shuttles
    DIRECTIONS = { 1 => "Morning", 2 => "Evening" }.freeze
    STRIP_DAYS = 14
    # How far a "Next change" banner looks ahead, and how far a "Service resumes" date is searched.
    NEXT_CHANGE_DAYS = 7
    RESUME_DAYS = 14
    # The schedule month picker ends this many days from today.
    SCHEDULE_DAYS = 92

    Employer = Data.define(:link, :company, :client) do
      def id = link.id

      def json
        name = client.name
        caps = name.scan(/[A-Z]/)
        { id:, name:, mark: (caps.size >= 2 ? caps.join : name.split.map { it[0] }.join).first(2).upcase, by: company.name, company_id: company.id }
      end
    end

    module_function

    # The employers a person can use: accepted links whose work email is not overdue, of active companies and kept clients.
    def employers(account, today: Date.current)
      identities = account.identities.select { it.email? && it.work? }.index_by(&:value)
      links = ActsAsTenant.without_tenant { ClientRider.where(app_account_id: account.id, status: "accepted").to_a }
      links = links.select { (identity = identities[it.matched_email]) && !identity.links_paused?(today) }
      companies = Company.active.where(id: links.map(&:company_id).uniq).index_by(&:id)
      links.filter_map do |link|
        company = companies[link.company_id] or next
        client = ActsAsTenant.with_tenant(company) { Client.kept.find_by(id: link.client_id) } or next
        Employer.new(link:, company:, client:)
      end.sort_by { [ it.client.name.downcase, it.id ] }
    end

    def employer!(account, id) = employers(account).find { it.id == id.to_i } || raise(ActiveRecord::RecordNotFound)

    # Run inside the employer's company (tenant) and time zone.
    def within(employer, &) = Parents.within(employer.company, &)

    # The employer's routes that still run: corporate shuttle trips of the client (ended ones are left out). Inside `within`.
    def trips(employer, today) = trips_of([ employer.client.id ], today)

    def trips_of(client_ids, today)
      Trip.kept.where(client_id: client_ids, kind: "corporate_shuttle").where("ends_on IS NULL OR ends_on >= ?", today)
          .includes(:client_site, stops: :client_site, runs: %i[times slots], vehicle_slots: [], assignments: :slots).order(:title, :id)
    end

    # The route (trip) of an employer by id, else 404. Inside `within`.
    def trip!(employer, id, today) = trips(employer, today).find(id)

    # Site names and route tags: the chips of a route.
    def tags(trip)
      (([ trip.client_site ] + trip.stops.map(&:client_site)).compact.map(&:name) + trip.route_tags).uniq
    end

    # The directions a route runs (a direction needs runs and stops): [1] or [1, 2].
    def directions(trip)
      [ 1, 2 ].select { |d| trip.runs.any? { it.direction == d } && trip.stops_in(d).size >= 2 }
    end

    def hm(minutes) = Clock.hm(minutes)

    # { 1 => "Morning" } of the directions a route has.
    def direction_list(trip) = directions(trip).map { { direction: it, name: DIRECTIONS.fetch(it) } }
  end
end
