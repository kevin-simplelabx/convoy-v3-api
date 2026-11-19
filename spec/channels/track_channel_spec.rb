require "rails_helper"

# Convoy App live screens: streams follow what ConvoyApp::Watch reads (screens themselves: home_spec, bookings_spec).
RSpec.describe TrackChannel do
  let(:account) { AppAccount.create!(first_name: "Rachel", last_name: "Tan", terms_accepted_at: Time.current) }
  let(:jwt) { ConvoyApp::IssueToken.call(account:).last }

  before { stub_connection(driver_jwt: nil, app_jwt: jwt) }

  it "streams each run on the screen, and positions only where the screen shows the bus" do
    allow(ConvoyApp::Watch).to receive(:call).and_return({ runs: [ 7, 8 ], positions: [ 8 ] })
    subscribe(screen: "booking_track", booking_id: 5)
    expect(ConvoyApp::Watch).to have_received(:call).with(account:, screen: "booking_track", params: hash_including("booking_id" => 5))
    expect(subscription).to have_stream_from("run:7")
    expect(subscription).to have_stream_from("run:8")
    expect(subscription).to have_stream_from("run:8:position")
    expect(subscription).not_to have_stream_from("run:7:position")
  end

  it "follows the screen as it changes, and says when it is gone" do
    allow(ConvoyApp::Watch).to receive(:call).and_return({ runs: [ 7 ], positions: [] }, { runs: [ 7 ], positions: [ 7 ] }, nil)
    subscribe(screen: "school_live", bus: "3-2026-11-03")
    expect(subscription.streams).to eq([ "run:7" ])

    subscription.send(:refresh) # the bus is now 10 minutes from the child's stop
    expect(subscription.streams).to contain_exactly("run:7", "run:7:position")

    subscription.send(:refresh) # nothing to track any more
    expect(subscription.streams).to eq([])
    expect(transmissions.last).to eq("type" => "gone")
  end

  it "refuses a screen that is not the person's, or an unknown screen" do
    subscribe(screen: "booking_track", booking_id: 999)
    expect(subscription).to be_rejected

    subscribe(screen: "live_map")
    expect(subscription).to be_rejected
  end

  it "closes the socket once the sign-in has ended" do
    allow(ConvoyApp::Watch).to receive(:call).and_return({ runs: [], positions: [] })
    subscribe(screen: "home")
    closed = []
    connection.define_singleton_method(:close) { |**opts| closed << opts } # the test stub has no socket to close
    subscription.send(:check_sign_in)
    expect(closed).to eq([])

    jwt.update!(exp: 1.minute.ago)
    subscription.send(:check_sign_in)
    expect(closed).to eq([ { reason: "unauthorized", reconnect: false } ])
  end
end
