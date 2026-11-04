require "rails_helper"

# Client Portal approvals (logic/app-feed.js apprCan, stepDone, apprAct): steps in order, who may decide (never the
# booker; step in by Super Admins and Admins; people checked again when deciding), any one / everyone, the same person
# on two steps, decline with a reason, and what Convoy OS sees.
RSpec.describe "Client Portal approvals" do
  let(:company) { create(:company, code: "SD", name: "SimpleDrive") }
  let(:staff) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard Rates", types: [ small ]))
      google = create(:client, name: "Google")
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      { small:, google:, tower_a:,
        priya: portal_user(google, email: "priya@google.com", role: "super"),
        linh: portal_user(google, email: "linh@google.com", role: "adm"),
        ken: portal_user(google, email: "ken@google.com", role: "fin"),
        tan: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]),
        dan: portal_user(google, email: "dan@google.com", role: "ssa", sites: [ tower_a ]),
        mo: portal_user(google, email: "mo@google.com", role: "member", sites: [ tower_a ]) }
    end
  end

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  def flow!(steps, same_person: "once")
    within_tenant(company) do
      flow = ClientApprovalFlow.for!(f[:google], nil)
      Portal::SaveApprovalRule.call(flow:, params: { name: "All bookings", steps:, same_person: })
    end
  end

  def submit(by = f[:mo])
    trip = { kind: "one_way", start_time: "09:00", pax: 10, points: [ { name: "Changi", use: "pu" }, { name: "Marina", use: "do" } ],
             vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }
    post api_v1_portal_bookings_path, params: { booking: { client_site_id: f[:tower_a].id, coordinator_name: "Mo", days: [ { date: "2026-11-05", trips: [ trip ] } ] } },
                                      headers: as(portal_token(by)), as: :json
    expect(response).to have_http_status(:created), json.inspect
    json[:data]
  end

  def decide(user, id, act, note = nil)
    post send(:"#{act}_api_v1_portal_booking_path", id), params: { note: }, headers: as(portal_token(user)), as: :json
  end

  it "runs the steps in order and sends the trips to the transport company after the last one" do
    flow!([ { who: [ "site" ] }, { who: [ "fin" ] } ])
    b = submit
    expect(b[:approval]).to include(status: "wait", name: "All bookings", current_step: 1, steps_count: 2,
                                    waiting_text: "Waiting for Dan or Tan (step 1 of 2)", can_decide: false)
    expect(b.dig(:approval, :steps, 1, :people)).to eq([ { id: f[:ken].id, name: "Ken", state: "will_be_asked" } ])

    get api_v1_portal_approvals_path, headers: as(portal_token(f[:tan])), as: :json
    expect(json.dig(:data, :waiting_for_you).pluck(:id)).to eq([ b[:id] ])
    get api_v1_portal_approvals_path, headers: as(portal_token(f[:ken])), as: :json
    expect(json[:data]).to include(waiting_for_you: [], waiting_for_others: [ hash_including(id: b[:id]) ])

    decide(f[:mo], b[:id], :approve)
    expect(response).to have_http_status(:forbidden) # their own booking
    decide(f[:ken], b[:id], :approve)
    expect(response).to have_http_status(:forbidden) # not on step 1

    decide(f[:tan], b[:id], :approve, "OK for the offsite")
    expect(json.dig(:data, :approval)).to include(current_step: 2, waiting_text: "Waiting for Ken (step 2 of 2)")
    expect(json.dig(:data, :approval, :steps, 0)).to include(state: "done", acts: [ hash_including(act: "approve", note: "OK for the offsite") ])
    expect(json.dig(:data, :status)).to eq("awaiting_approval")
    decide(f[:dan], b[:id], :approve)
    expect(response).to have_http_status(:forbidden) # step 1 is done

    decide(f[:ken], b[:id], :approve)
    expect(json.dig(:data, :approval)).to include(status: "ok", waiting_text: nil)
    expect(json.dig(:data, :status)).to eq("sent")
    within_tenant(company) do
      expect(BookingEvent.pluck(:kind, :message)).to eq([ [ "client_approved", "Approved by Ken in Google's approval flow, sent to you" ] ])
    end
  end

  it "declines with a reason: every waiting trip is declined by the client" do
    flow!([ { who: [ "site" ] } ])
    b = submit
    decide(f[:tan], b[:id], :decline, " ")
    expect(json.dig(:error, :message)).to eq("Say why it is declined, the person who booked sees it")
    decide(f[:tan], b[:id], :decline, "Use the shuttle")
    expect(json[:data]).to include(status: "declined", estimate_amount: "0.0")
    expect(json.dig(:data, :trips, 0, :rejection)).to include(by: "Tan", by_client: true, reason: "Use the shuttle")
    expect(json.dig(:data, :approval)).to include(status: "no")
    within_tenant(company) do
      expect(BookingTrip.last.rejected_by_client_user).to eq(f[:tan])
      expect(BookingEvent.last.message).to eq("Declined by Tan in Google's approval flow: Use the shuttle")
    end
  end

  it "lets Super Admins and Admins step in, and asks again whether people are still right for the step" do
    flow!([ { who: [ "site" ] } ])
    b = submit
    get api_v1_portal_booking_path(b[:id]), headers: as(portal_token(f[:linh])), as: :json
    expect(json.dig(:data, :approval)).to include(can_decide: true, stepping_in: true)

    within_tenant(company) { f[:tan].update!(role: "member") } # no longer a Site Admin
    get api_v1_portal_booking_path(b[:id]), headers: as(portal_token(f[:tan])), as: :json
    expect(json.dig(:data, :approval)).to include(can_decide: false, waiting_text: "Waiting for Dan (step 1 of 1)")
    expect(json.dig(:data, :approval, :steps, 0, :people)).to include({ id: f[:tan].id, name: "Tan", state: "no_longer" })

    within_tenant(company) { f[:dan].discard! }
    get api_v1_portal_booking_path(b[:id]), headers: as(portal_token(f[:linh])), as: :json
    expect(json.dig(:data, :approval, :waiting_text)).to eq("Waiting for Linh or Priya (step 1 of 1)") # no one left: the Admins
    decide(f[:linh], b[:id], :approve)
    expect(json.dig(:data, :approval, :status)).to eq("ok")
  end

  it "needs everyone on an Everyone step; the same person on two steps approves both (once) or not (other)" do
    flow!([ { who: [ "site" ], need: "all" }, { who: [ "people" ], people_ids: [ f[:tan].id, f[:ken].id ] } ])
    b = submit
    decide(f[:tan], b[:id], :approve)
    expect(json.dig(:data, :approval)).to include(current_step: 1, waiting_text: "Waiting for Dan (step 1 of 2)")
    decide(f[:dan], b[:id], :approve)
    # Tan approved step 1 and is on step 2: carried, which finishes step 2 (any one).
    expect(json.dig(:data, :approval, :status)).to eq("ok")
    expect(json.dig(:data, :approval, :steps, 1, :people)).to include({ id: f[:tan].id, name: "Tan", state: "carried" })

    within_tenant(company) { ClientApprovalRule.where(otherwise: false).update_all(same_person: "other") }
    b = submit
    decide(f[:tan], b[:id], :approve)
    decide(f[:dan], b[:id], :approve)
    expect(json.dig(:data, :approval)).to include(current_step: 2, waiting_text: "Waiting for Ken (step 2 of 2)")
    decide(f[:tan], b[:id], :approve)
    expect(response).to have_http_status(:forbidden) # someone else (Ken) is left
  end

  it "shows Convoy OS the client's approval and keeps the booking unchanged while it waits" do
    flow!([ { who: [ "site" ] } ])
    b = submit
    sign_in_as(staff)
    get api_v1_booking_path(b[:id]), as: :json
    expect(json[:data]).to include(can_edit: false, status_label: "Awaiting Client Approval",
                                   client_approval: hash_including(status: "wait", waiting_text: "Waiting for Dan or Tan (step 1 of 1)"))
    expect(json.dig(:data, :days, 0, :trips, 0)).to include(can_approve: false, can_reject: false)
    patch api_v1_booking_path(b[:id]), params: { booking: { client_id: f[:google].id, coordinator_name: "X", days: [] } }, as: :json
    expect(json.dig(:error, :message)).to eq("Waiting for Google's own approval in the Client Portal. It can't be changed until then")

    get api_v1_portal_me_path, headers: as(portal_token(f[:tan])), as: :json
    expect(json.dig(:data, :menu, :approvals)).to be(true)
  end
end
