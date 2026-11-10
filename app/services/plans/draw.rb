# Draw Routes (port of Convoy OS createManualPlan): an empty draft plan for the Plan For date, every rider of the session
# unassigned — riders at a stop by stop (NOT_ROUTED), riders with no stop or more than one on their own (RIDER_NO_STOP,
# RIDER_IN_CONFLICT) — with the engine's parameters (defaults, the company's, the session) and the summary of no routes.
module Plans
  class Draw < ApplicationService
    def initialize(school, session:, date:, user:)
      @school = school
      @session = session
      @date = date
      @user = user
    end

    def call
      raise Error, "Pick AM, PM or ASA / CCA" unless SchoolPlan::SESSIONS.key?(@session)

      input = Routing::Input.new(@school, @session, @date).call
      unassigned = input[:groups].map { |g| entry(g[:uid], g[:riders], "NOT_ROUTED", g[:stopId]) } +
                   input[:noStop].map { entry("ns:#{it[:rid]}", [ it[:rid] ], "RIDER_NO_STOP", it[:name]) } +
                   input[:conflicts].map { entry("cf:#{it[:rid]}", [ it[:rid] ], "RIDER_IN_CONFLICT", it[:name]) }
      SchoolPlan.transaction do
        plan = @school.plans.create!(name: Plans.next_name(@school, @session), session: @session, effective_from: @date, in_use: false, source: "manual",
                                     params: Routing.defaults.merge(input[:params]), unassigned:, created_by: @user)
        plan.update!(summary: Plans.summary(plan, unassigned))
        plan
      end
    end

    private

    def entry(gid, rids, reason, label) = { "gid" => gid, "riders" => rids, "n" => rids.size, "reason" => reason, "label" => label }
  end
end
