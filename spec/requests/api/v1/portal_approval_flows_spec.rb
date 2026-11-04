require "rails_helper"

# Client Portal › Settings › Approval Flows: the organisation's and sites' flows, rules, Otherwise, Try a Booking.
RSpec.describe "Client Portal approval flows" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:s) do
    within_tenant(company) do
      google = create(:client, name: "Google")
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      tower_b = google.sites.create!(company_id: company.id, name: "Tower B")
      { google:, tower_a:, tower_b:,
        admin: portal_user(google, email: "linh@google.com", role: "adm"),
        fin: portal_user(google, email: "ken@google.com", role: "fin"),
        sa_a: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]),
        bee: portal_user(google, email: "bee@google.com", role: "member", sites: [ tower_b ]),
        mo: portal_user(google, email: "mo@google.com", role: "member", sites: [ tower_a ]) }
    end
  end

  it "shows the flows a person sets: the organisation for organisation-wide roles, then their sites" do
    get api_v1_portal_approval_flows_path, headers: as(portal_token(s[:admin])), as: :json
    expect(json[:data].pluck(:for)).to eq([ "organisation", s[:tower_a].id, s[:tower_b].id ])
    expect(json.dig(:data, 0)).to include(on: false, rules: [], otherwise: hash_including(steps: [], approved_automatically: true))

    get api_v1_portal_approval_flows_path, headers: as(portal_token(s[:sa_a])), as: :json
    expect(json[:data].pluck(:for)).to eq([ s[:tower_a].id ])
    get api_v1_portal_approval_flows_path, headers: as(portal_token(s[:fin])), as: :json
    expect(response).to have_http_status(:forbidden)
    within_tenant(company) { expect(ClientApprovalFlow.count).to eq(0) } # reading saves nothing
  end

  it "adds, edits, orders and deletes rules; adding one turns the flow on" do
    token = portal_token(s[:admin])
    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "", steps: [ { who: [ "site" ] } ] } }
    expect(json.dig(:error, :details, :name)).to eq([ "Name is needed: name the rule, e.g. Large bookings" ])
    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "Named", steps: [ { who: [ "people" ] } ] } }
    expect(json.dig(:error, :message)).to eq("Pick at least one person for each step with Named People")
    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "Six", steps: Array.new(6) { { who: [ "admins" ] } } } }
    expect(json.dig(:error, :message)).to eq("Up to 5 steps")

    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "Large bookings", when: { over: 1000, site_ids: [ s[:tower_a].id ], kinds: [ "airport" ] },
                           steps: [ { who: %w[site fin], need: "all" }, { who: [ "people" ], people_ids: [ s[:fin].id ] } ], same_person: "other" } }
    expect(response).to have_http_status(:created), json.inspect
    large = json.dig(:data, :rules, 0)
    expect(json[:data][:on]).to be(true)
    expect(large[:when_text]).to eq([ "Site is Tower A", "Estimate over S$1,000", "Includes Airport Transfer" ])
    expect(large[:steps].pluck(:text)).to eq([ "Site Admins or Finance, everyone", "Ken, any one" ])

    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "Short notice", when: { lead_days: 2 }, steps: [] } }
    expect(json.dig(:data, :rules).pluck(:name)).to eq([ "Large bookings", "Short notice" ])
    expect(json.dig(:data, :rules, 1)).to include(approved_automatically: true, when_text: [ "Booked less than 2 days ahead" ])
    post move_rule_api_v1_portal_approval_flow_path("organisation", json.dig(:data, :rules, 1, :id)), params: { direction: "up" }, headers: as(token), as: :json
    expect(json.dig(:data, :rules).pluck(:name)).to eq([ "Short notice", "Large bookings" ])

    patch rule_api_v1_portal_approval_flow_path("organisation", large[:id]), headers: as(token), as: :json,
          params: { rule: { name: "Large", when: { over: 2000 }, steps: [ { who: [ "admins" ] } ] } }
    expect(json.dig(:data, :rules, 1)).to include(name: "Large", when_text: [ "Estimate over S$2,000" ])
    delete rule_api_v1_portal_approval_flow_path("organisation", large[:id]), headers: as(token), as: :json
    expect(json.dig(:data, :rules).pluck(:name)).to eq([ "Short notice" ])

    patch otherwise_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
          params: { rule: { steps: [ { who: [ "mgr" ] } ], same_person: "other" } }
    expect(json.dig(:data, :otherwise)).to include(same_person: "other", steps: [ hash_including(text: "Their Manager, any one") ])
    patch api_v1_portal_approval_flow_path("organisation"), params: { on: false }, headers: as(token), as: :json
    expect(json.dig(:data, :on)).to be(false)
  end

  it "lets site roles set only their own sites' flows, with people who cover the site" do
    token = portal_token(s[:sa_a])
    patch api_v1_portal_approval_flow_path("organisation"), params: { on: true }, headers: as(token), as: :json
    expect(response).to have_http_status(:forbidden)
    post rules_api_v1_portal_approval_flow_path(s[:tower_b].id), params: { rule: { name: "B" } }, headers: as(token), as: :json
    expect(response).to have_http_status(:forbidden)

    post rules_api_v1_portal_approval_flow_path(s[:tower_a].id), headers: as(token), as: :json,
         params: { rule: { name: "A", when: { site_ids: [ s[:tower_b].id ] }, steps: [ { who: [ "people" ], people_ids: [ s[:bee].id ] } ] } }
    expect(json.dig(:error, :message)).to eq("Pick people who cover Tower A")
    post rules_api_v1_portal_approval_flow_path(s[:tower_a].id), headers: as(token), as: :json,
         params: { rule: { name: "A", when: { site_ids: [ s[:tower_b].id ] }, steps: [ { who: [ "people" ], people_ids: [ s[:sa_a].id ] } ] } }
    expect(json.dig(:data, :rules, 0, :when_text)).to eq([ "Every booking" ]) # Site Is is for the organisation's flow only
    expect(json[:data]).to include(for: s[:tower_a].id, on: true)
  end

  it "tries a booking without saving it, and shows Approvals to people named in a flow" do
    token = portal_token(s[:admin])
    post rules_api_v1_portal_approval_flow_path("organisation"), headers: as(token), as: :json,
         params: { rule: { name: "Large", when: { over: 1000 }, steps: [ { who: [ "people" ], people_ids: [ s[:mo].id ] } ] } }

    post try_api_v1_portal_approval_flows_path, params: { site_id: s[:tower_a].id, booked_by_id: s[:bee].id, kind: "one_way", estimate: 1500, lead_days: 7 },
                                                headers: as(token), as: :json
    expect(json[:data]).to include(need: true, flow: "organisation", name: "Large",
                                   steps: [ hash_including(label: "Mo", people: [ { id: s[:mo].id, name: "Mo" } ], fallback: false) ])
    post try_api_v1_portal_approval_flows_path, params: { estimate: 500 }, headers: as(token), as: :json
    expect(json[:data]).to include(need: false, name: "Otherwise")

    get api_v1_portal_me_path, headers: as(portal_token(s[:mo])), as: :json
    expect(json.dig(:data, :menu, :approvals)).to be(true)
  end
end
