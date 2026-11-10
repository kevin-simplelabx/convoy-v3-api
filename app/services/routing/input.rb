# The routing engine's input for a school's session on a plan date (port of engInput in Convoy OS): riders on that date
# who ride the session, grouped by their one stop (Stop Assignment); riders with no stop or with more than one are left
# out and listed as { rid, name } (the engine labels its unassigned riders with them). Each group carries the stop's points this school uses. The current plan of the session (as the engine
# shaped it) lets Keep Current stay close to it. Parameters: the company's, the priority preset, the session, and the
# school's bus attendant rule.
module Routing
  class Input
    attr_reader :no_stop, :conflicts

    def initialize(school, session, date, params: {})
      @school = school
      @session = session
      @date = date
      @params = params
    end

    def call
      assignment = SchoolStops::Assignment.new(@school, date: @date)
      groups = {}
      no_stop = []
      conflicts = []
      assignment.riders.each do |r|
        next unless rides?(r)

        stops = r[:candidates].map { it[:stop_id] }.uniq
        if stops.empty? then no_stop << r.slice(:rid, :name)
        elsif stops.size > 1 then conflicts << r.slice(:rid, :name)
        else (groups[stops.first] ||= []) << r[:rid]
        end
      end
      @no_stop = no_stop.pluck(:rid)
      @conflicts = conflicts.pluck(:rid)
      { school: { lat: @school.lat.to_f, lng: @school.lng.to_f, name: @school.name, short: @school.short },
        groups: groups.map { |stop_id, rids| group(stop_id, rids) }, noStop: no_stop, conflicts:,
        current: current, params: params }
    end

    private

    def rides?(r)
      case @session
      when "am" then r[:am]
      when "pm" then r[:pm]
      else Array(r[:cca_days]).any?
      end
    end

    def group(stop_id, rids)
      ss = @school.school_stops.includes(stop: :points).find_by!(stop_id:)
      { uid: stop_id.to_s, stopId: ss.stop.code, name: ss.stop.name, riders: rids,
        points: ss.stop.points.reject { ss.off_point_ids.include?(it.id) }.map do |p|
          { pid: p.id.to_s, sfx: p.suffix, label: p.pudo_code, lat: p.lat.to_f, lng: p.lng.to_f, usage: p.usage, sizes: p.sizes }
        end }
    end

    def current
      plan = @school.plans.where(session: @session).includes(:routes).find { it.state(@date) == "current" }
      routes = plan&.routes&.filter_map(&:engine_route)
      routes.present? ? { routes: } : nil
    end

    def params
      ba = @school.attendant_policy
      (RoutingSetting.first&.params || {}).merge(@params.stringify_keys)
                                          .merge("session" => SESSION_KEYS[@session], "attendant" => ba&.needs == "all" ? "ALL_BUSES" : "STATUTORY")
    end
  end
end
