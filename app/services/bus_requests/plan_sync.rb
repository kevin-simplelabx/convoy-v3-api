# Write a confirmed request into the school's route plans from its date, once (Convoy OS planSync / pcOf): a new child
# once paid (join), a new address once confirmed or agreed (move), a session added or dropped, a leaver from the day
# after the last day, a change of address that stopped the service (leave). The result lines stay on the request.
module BusRequests
  class PlanSync < ApplicationService
    def initialize(req, user: nil)
      @req = req
      @user = user
    end

    def call
      list = changes
      return if list.empty?

      any = false
      lines = list.map do |c|
        r = Plans::ApplyChange.call(@req.school, c, request: @req)
        any ||= r[:ok]
        r[:ok] && r[:impact].present? ? "#{r[:txt]}. #{r[:impact].join('. ')}" : r[:txt]
      end
      @req.update!(planned_at: Time.current, planned_ok: any, plan_lines: lines)
      tell = any ? ". The parents whose times change, and the driver and attendant the day before, are to be told" : ""
      @req.log!("Route plan: #{lines.join(' | ')}#{tell}", by: @user || "Convoy")
      lines
    end

    def changes
      r = @req
      rid = r.school_rider&.rid
      return [] if rid.nil? || r.planned_at

      st = r.live_status
      home = { ll: r.lat && [ r.lat.to_f, r.lng.to_f ], postal: r.postal.to_s.gsub(/\D/, "") }
      mk = ->(session, from, op, **o) { { session:, from:, op:, rid:, home: }.merge(o) }
      both = %w[AM PM]
      case r.kind
      when "new"
        return [] unless !r.renew && st == "Active" && r.start_on

        both.select { it == "AM" ? r.am : r.pm }.map { mk.(it, r.start_on, "join") }
      when "adr"
        return both.map { mk.(it, r.effective_on, "move", stop_name: r.new_stop) } if st == "Active" && r.effective_on && home[:ll]
        return both.map { mk.(it, r.effective_on, "leave") } if st == "Stopped" && r.effective_on

        []
      when "svc"
        return [] unless st == "Active" && r.effective_on

        has = ->(am, pm, s) { s == "AM" ? am != false : pm != false }
        both.reject { has.(r.old_am, r.old_pm, it) == has.(r.am, r.pm, it) }.map { mk.(it, r.effective_on, has.(r.am, r.pm, it) ? "join" : "drop") }
      when "stop"
        %w[Stopping Stopped].include?(st) && r.last_on ? both.map { mk.(it, r.last_on + 1, "leave") } : []
      else []
      end
    end
  end
end
