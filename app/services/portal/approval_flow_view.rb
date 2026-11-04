# An approval flow as the Approval Flows tab draws it: on / off, the rules in order with their conditions (ids and the
# words, logic/app-feed.js whenTxt) and steps (stepTxt), then Otherwise. Removed sites, people and teams no longer
# show; a rule that still asks for them shows "a removed site" / "a removed person or team" and matches nothing.
module Portal
  class ApprovalFlowView < ApplicationService
    KIND_LABELS = { "one_way" => "Ad Hoc / Charter", "two_way" => "Ad Hoc / Charter Two Way", "disposal" => "Disposal",
                    "airport" => "Airport Transfer" }.freeze

    def initialize(flow:)
      @flow = flow
    end

    def call
      rules = @flow.new_record? ? [] : @flow.rules.includes(rule_sites: :client_site, rule_bookers: :client_user, rule_teams: :client_team,
                                   steps: { step_people: :client_user }).to_a
      { for: @flow.organisation? ? "organisation" : @flow.client_site_id, site: @flow.client_site && { id: @flow.client_site.id, name: @flow.client_site.name },
        on: @flow.on, rules: rules.reject(&:otherwise?).map { rule(it) }, otherwise: otherwise(rules.find(&:otherwise?)) }
    end

    private

    def otherwise(r)
      r ? rule(r) : { id: nil, name: "Otherwise", position: 0, same_person: "once", approved_automatically: true, when: nil,
                      when_text: [ "Every other booking" ], steps: [] }
    end

    def rule(r)
      sites = r.rule_sites.map(&:client_site)
      bookers = r.rule_bookers.map(&:client_user).select(&:kept?)
      teams = r.rule_teams.map(&:client_team)
      { id: r.id, name: r.otherwise? ? "Otherwise" : r.name, position: r.position, same_person: r.same_person, approved_automatically: r.steps.empty?,
        when: { site_ids: sites.map(&:id), booker_ids: bookers.map(&:id), team_ids: teams.map(&:id), kinds: r.trip_kinds,
                over: r.over_amount&.to_f, lead_days: r.lead_days },
        when_text: r.otherwise? ? [ "Every other booking" ] : when_text(r, sites, bookers, teams),
        steps: r.steps.map { step(it) } }
    end

    def step(s)
      people = s.step_people.map(&:client_user).select(&:kept?)
      { id: s.id, who: s.who, need: s.need, people: people.map { { id: it.id, name: it.name } },
        text: "#{ApprovalRoute.step_label(s.who, people)}, #{s.need == 'all' ? 'everyone' : 'any one'}" }
    end

    def when_text(r, sites, bookers, teams)
      out = []
      out << "Site is #{list(sites.map(&:name).presence || [ 'a removed site' ])}" if r.sites_condition
      out << "Estimate over #{money(r.over_amount)}" if r.over_amount
      by = teams.map { "#{it.name} team" } + bookers.map(&:name)
      out << "Booked by #{list(by.presence || [ 'a removed person or team' ])}" if r.booked_by_condition
      out << "Includes #{list(r.trip_kinds.map { KIND_LABELS.fetch(it) })}" if r.trip_kinds.any?
      out << "Booked less than #{r.lead_days} #{'day'.pluralize(r.lead_days)} ahead" if r.lead_days
      out.presence || [ "Every booking" ]
    end

    def list(names) = names.size <= 2 ? names.join(" or ") : "#{names[0..-2].join(', ')} or #{names.last}"
    def money(v) = "S$#{v.to_d == v.to_i ? v.to_i.to_fs(:delimited) : format('%.2f', v)}"
  end
end
