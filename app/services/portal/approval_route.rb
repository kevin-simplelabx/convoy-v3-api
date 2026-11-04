# The approval a booking needs (logic/app-feed.js routeFor, routeMatch, stepPeople): the flow that decides (the site's
# own flow when it is on, else the organisation's; off = no approval), the first rule whose conditions all match (else
# Otherwise), and for each step the people asked. People: Their Manager (the booker's, else their team's), Site Admins
# (Site Super Admins and Site Admins covering the booking's site), Finance (Finance Admins and Site Finance covering
# it), Admins (Super Admins and Admins), named people. Never the booker, never removed people. A step left with no one
# falls to the Admins; still no one (the only Admin booked it) = the step is dropped. No steps = no approval needed.
module Portal
  class ApprovalRoute < ApplicationService
    Step = Data.define(:position, :who, :need, :label, :people, :fallback)
    Result = Data.define(:need, :flow, :rule, :name, :steps, :same_person) do
      def to_h
        { need:, flow: flow && (flow.organisation? ? "organisation" : "site"), rule_id: rule&.id, name:, same_person:,
          steps: steps.map { |s| { position: s.position, who: s.who, need: s.need, label: s.label, fallback: s.fallback,
                                   people: s.people.map { |u| { id: u.id, name: u.name } } } } }
      end
    end

    # booking: { site_id, booker (client user or nil), kinds [], amount, lead (days ahead) }
    def initialize(client:, booking:)
      @client = client
      @booking = booking
      @site_id = booking[:site_id]
      @booker = booking[:booker]
    end

    def call
      flow = deciding_flow
      return Result.new(need: false, flow:, rule: nil, name: nil, steps: [], same_person: "once") unless flow&.on?

      rules = flow.rules.includes(:rule_sites, :rule_bookers, :rule_teams, steps: { step_people: :client_user }).to_a
      rule = rules.reject(&:otherwise?).find { it.match?(@booking) } || rules.find(&:otherwise?)
      steps = rule.steps.each_with_index.filter_map { |s, i| step(s, i + 1) }
      Result.new(need: steps.any?, flow:, rule:, name: route_name(flow, rule), steps:, same_person: rule.same_person)
    end

    # Is this person still in the step's groups for the booking (a decision checks it again: role or sites may have
    # changed since the booking was sent). Named people are not checked again.
    def self.in_group?(user, who:, site_id:, booker:)
      return false unless user.kept?

      who.any? do |k|
        case k
        when "mgr" then booker&.manager_for_approval&.id == user.id
        when "site" then user.ssa? || user.sa? ? user.covers?(site_id) : false
        when "fin" then user.fin? || (user.sfin? && user.covers?(site_id))
        when "admins" then user.super? || user.adm?
        when "people" then false
        end
      end
    end

    def self.step_label(who, people)
      names = who.map { |k| k == "people" ? (people.map(&:name).join(", ").presence || "No one picked") : ClientApprovalStep::WHO.fetch(k) }
      names.size <= 2 ? names.join(" or ") : "#{names[0..-2].join(', ')} or #{names.last}"
    end

    private

    def deciding_flow
      flows = ClientApprovalFlow.where(client: @client).to_a
      own = @site_id && flows.find { it.client_site_id == @site_id }
      own&.on? ? own : flows.find(&:organisation?)
    end

    def users = @users ||= @client.users.kept.includes(:user_sites, :manager, team: :manager).order(:name).to_a

    def step(s, position)
      named = s.step_people.map(&:client_user).select(&:kept?)
      people = users.select { |u| self.class.in_group?(u, who: s.who, site_id: @site_id, booker: @booker) || (s.who.include?("people") && named.include?(u)) }
      people = people.reject { it.id == @booker&.id }
      fallback = people.empty?
      people = users.select { (it.super? || it.adm?) && it.id != @booker&.id } if fallback
      return if people.empty?

      Step.new(position:, who: s.who, need: s.need, label: self.class.step_label(s.who, named), people:, fallback:)
    end

    def route_name(flow, rule)
      name = rule.otherwise? ? "Otherwise" : rule.name
      flow.organisation? ? name : "#{flow.client_site.name} flow: #{name}"
    end
  end
end
