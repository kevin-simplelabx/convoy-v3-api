require "rails_helper"

# Which approval a booking needs (logic/app-feed.js routeFor / routeMatch / stepPeople).
RSpec.describe Portal::ApprovalRoute, :tenant do
  let(:client) { create(:client, name: "Google") }
  let(:tower_a) { client.sites.create!(company_id: client.company_id, name: "Tower A") }
  let(:tower_b) { client.sites.create!(company_id: client.company_id, name: "Tower B") }
  let!(:people) do
    mk = lambda do |name, role, sites = []|
      account = PortalAccount.for_email!("#{name.downcase}@google.com", name:)
      u = client.users.create!(company_id: client.company_id, name:, email: account.email, role:, portal_account: account)
      sites.each { u.user_sites.create!(client_site: it) }
      u
    end
    { priya: mk.("Priya", "super"), linh: mk.("Linh", "adm"), ken: mk.("Ken", "fin"), tan: mk.("Tan", "sa", [ tower_a ]),
      bee: mk.("Bee", "sfin", [ tower_b ]), mo: mk.("Mo", "member", [ tower_a ]) }
  end
  let(:org) { ClientApprovalFlow.for!(client, nil) }

  def route(booker: people[:mo], site: tower_a, amount: 500, kinds: [ "one_way" ], lead: 7)
    described_class.call(client:, booking: { site_id: site&.id, booker:, kinds:, amount:, lead: })
  end

  def rule(flow, name, when_ = {}, steps = [ { who: [ "site" ] } ], same_person: "once")
    Portal::SaveApprovalRule.call(flow:, params: { name:, when: when_, steps:, same_person: })
  end

  it "needs nothing while the flow is off, or when the rule has no steps" do
    expect(route.need).to be(false)
    rule(org, "Small", { over: 1000 }, [])
    org.otherwise.update!(same_person: "once")
    expect(route.need).to be(false)
    expect(route.name).to eq("Otherwise")
  end

  it "takes the first rule whose conditions all match, else Otherwise" do
    rule(org, "Large", { over: 1000 }, [ { who: [ "fin" ] }, { who: [ "admins" ], need: "all" } ])
    rule(org, "Airport", { kinds: [ "airport" ] }, [ { who: [ "site" ] } ])
    Portal::SaveApprovalRule.call(flow: org, rule: org.otherwise, params: { steps: [ { who: [ "mgr" ] } ] })

    big = route(amount: 1500)
    expect(big.name).to eq("Large")
    expect(big.steps.map { it.people.map(&:name) }).to eq([ %w[Ken], %w[Linh Priya] ])
    expect(big.steps.map(&:label)).to eq([ "Finance", "Admins" ])
    expect(route(kinds: %w[one_way airport]).name).to eq("Airport")
    expect(route(kinds: %w[airport]).steps.first.people.map(&:name)).to eq(%w[Tan])
    expect(route(kinds: %w[airport], site: tower_b).steps.first).to have_attributes(fallback: true) # no Site Admin at B → Admins
  end

  it "asks Their Manager (own, else the team's), never the booker; drops a step nobody is left for" do
    team = client.teams.create!(company_id: client.company_id, name: "Events", manager: people[:tan])
    people[:mo].update!(team:)
    Portal::SaveApprovalRule.call(flow: org, rule: org.otherwise, params: { steps: [ { who: [ "mgr" ] } ] })
    org.update!(on: true)
    expect(route.steps.first.people.map(&:name)).to eq(%w[Tan])
    people[:mo].update!(manager: people[:ken])
    expect(route.steps.first.people.map(&:name)).to eq(%w[Ken])

    rule(org, "Admins", { booker_ids: [ people[:priya].id ] }, [ { who: [ "admins" ] } ])
    expect(route(booker: people[:priya]).steps.first.people.map(&:name)).to eq(%w[Linh])
    people[:linh].discard!
    expect(route(booker: people[:priya]).need).to be(false) # only Admin booked it: the step is dropped
  end

  it "matches Booked By people or teams, Site Is, and booked less than N days ahead" do
    team = client.teams.create!(company_id: client.company_id, name: "Events")
    people[:mo].update!(team:)
    rule(org, "Events team", { team_ids: [ team.id ] })
    expect(route.name).to eq("Events team")
    expect(route(booker: people[:tan]).name).to eq("Otherwise")

    rule(org, "Short notice at B", { site_ids: [ tower_b.id ], lead_days: 3 })
    expect(route(booker: people[:tan], site: tower_b, lead: 2).name).to eq("Short notice at B")
    expect(route(booker: people[:tan], site: tower_b, lead: 3).name).to eq("Otherwise")

    team.destroy! # the rule still asks for the team: it matches nothing now
    expect(route.name).to eq("Otherwise")
  end

  it "uses a site's own flow when it is on" do
    rule(org, "Org rule", {}, [ { who: [ "admins" ] } ])
    own = ClientApprovalFlow.for!(client, tower_a)
    rule(own, "Tower A", {}, [ { who: [ "people" ], people_ids: [ people[:tan].id ] } ])
    expect(route.name).to eq("Tower A flow: Tower A")
    expect(route(site: tower_b).name).to eq("Org rule")
    own.update!(on: false)
    expect(route.name).to eq("Org rule")
  end

  it "checks again whether someone is still in a step's group" do
    expect(described_class.in_group?(people[:tan], who: [ "site" ], site_id: tower_a.id, booker: people[:mo])).to be(true)
    people[:tan].update!(role: "member")
    expect(described_class.in_group?(people[:tan], who: [ "site" ], site_id: tower_a.id, booker: people[:mo])).to be(false)
    expect(described_class.in_group?(people[:bee], who: [ "fin" ], site_id: tower_a.id, booker: people[:mo])).to be(false)
    expect(described_class.in_group?(people[:ken], who: [ "fin" ], site_id: tower_a.id, booker: people[:mo])).to be(true)
  end
end
