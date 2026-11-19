require "rails_helper"

# WebSocket sign-in: a one-time ticket of a Driver app or Convoy App sign-in opens /cable; anything else is refused.
RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:driver_jwt) { DriverApp::IssueToken.call(account: DriverAccount.create!(phone: "+6591234567")).last }
  let(:app_jwt) { ConvoyApp::IssueToken.call(account: AppAccount.create!(first_name: "Rachel", last_name: "Tan", terms_accepted_at: Time.current)).last }

  it "opens with a Driver app or a Convoy App ticket, once" do
    ticket = CableTicket.issue!(driver_jwt)
    connect "/cable", params: { ticket: }
    expect(connection.driver_jwt).to eq(driver_jwt)
    expect(connection.app_jwt).to be_nil
    expect { connect "/cable", params: { ticket: } }.to have_rejected_connection

    connect "/cable", params: { ticket: CableTicket.issue!(app_jwt) }
    expect(connection.app_jwt).to eq(app_jwt)
  end

  it "refuses no ticket, a wrong or expired ticket, and a ticket of a sign-in that ended" do
    expect { connect "/cable" }.to have_rejected_connection
    expect { connect "/cable", params: { ticket: "nope" } }.to have_rejected_connection

    old = CableTicket.issue!(driver_jwt)
    travel_to(61.seconds.from_now) { expect { connect "/cable", params: { ticket: old } }.to have_rejected_connection }

    ticket = CableTicket.issue!(app_jwt)
    app_jwt.destroy!
    expect { connect "/cable", params: { ticket: } }.to have_rejected_connection
    expect(CableTicket.where(app_jwt_id: app_jwt.id)).to be_empty # the ticket went with its sign-in
  end

  it "keeps only the ticket's digest" do
    ticket = CableTicket.issue!(driver_jwt)
    expect(CableTicket.last.token_digest).not_to include(ticket)
    expect(CableTicket.last.expires_at).to be_within(1.second).of(60.seconds.from_now)
  end
end
