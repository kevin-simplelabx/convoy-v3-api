# Add or change a rule of an approval flow, or its Otherwise (steps and same_person only), from the rule editor. Conditions:
# Site Is (the organisation's flow only), Booked By (people and teams), Includes a Trip Type, Estimate Over S$, Booked Less
# Than N days ahead. Up to 5 steps; Named People needs at least one person, from the people covering the flow's site.
# Adding a rule turns the flow on.
module Portal
  class SaveApprovalRule < ApplicationService
    def initialize(flow:, params:, rule: nil)
      @flow = flow
      @client = flow.client
      @params = params.to_h.deep_symbolize_keys
      @rule = rule || flow.rules.new(company_id: flow.company_id, position: next_position)
    end

    def call
      ClientApprovalRule.transaction do
        @flow.lock!
        assign
        @rule.save!
        save_conditions unless @rule.otherwise?
        save_steps
        @flow.update!(on: true) if @rule.previously_new_record?
      end
      @rule
    end

    private

    def next_position = @flow.rules.reject(&:otherwise?).map(&:position).max.to_i + 1

    def assign
      @rule.same_person = @params[:same_person] if @params.key?(:same_person)
      return if @rule.otherwise?

      w = @params[:when] || {}
      @rule.assign_attributes(name: @params[:name], trip_kinds: Array(w[:kinds]).compact_blank.uniq,
                              over_amount: w[:over].presence, lead_days: w[:lead_days].presence)
      @site_ids = @flow.organisation? ? ids(w[:site_ids]) : []
      @booker_ids = ids(w[:booker_ids])
      @team_ids = ids(w[:team_ids])
      @rule.sites_condition = @site_ids.any?
      @rule.booked_by_condition = @booker_ids.any? || @team_ids.any?
    end

    def save_conditions
      check_all!(@client.sites, @site_ids, "Some sites are not sites of #{@client.name}")
      check_all!(@client.users.kept, @booker_ids, "Some people are not users of #{@client.name}")
      check_all!(@client.teams, @team_ids, "Some teams are not teams of #{@client.name}")
      @rule.rule_sites.delete_all
      @rule.rule_bookers.delete_all
      @rule.rule_teams.delete_all
      @site_ids.each { @rule.rule_sites.create!(client_site_id: it) }
      @booker_ids.each { @rule.rule_bookers.create!(client_user_id: it) }
      @team_ids.each { @rule.rule_teams.create!(client_team_id: it) }
    end

    def save_steps
      rows = Array(@params[:steps])
      raise Error, "Up to #{ClientApprovalRule::MAX_STEPS} steps" if rows.size > ClientApprovalRule::MAX_STEPS

      @rule.steps.destroy_all
      rows.each_with_index do |row, i|
        who = Array(row[:who]).compact_blank.uniq
        people = who.include?("people") ? ids(row[:people_ids]) : []
        raise Error, "Pick at least one person for each step with Named People" if who.include?("people") && people.empty?

        check_people!(people)
        step = @rule.steps.create!(position: i, who:, need: row[:need].presence || "any")
        people.each { step.step_people.create!(client_user_id: it) }
      end
    end

    # Named people: users of the client covering the flow's site (any user for the organisation's flow).
    def check_people!(people)
      users = @client.users.kept.where(id: people).includes(:user_sites).to_a
      ok = users.size == people.size && (@flow.organisation? || users.all? { it.covers?(@flow.client_site_id) })
      raise Error, "Pick people who cover #{@flow.organisation? ? @client.name : @flow.client_site.name}" unless ok
    end

    def check_all!(scope, wanted, message)
      raise Error, message if scope.where(id: wanted).count != wanted.size
    end

    def ids(list) = Array(list).compact_blank.map(&:to_i).uniq
  end
end
