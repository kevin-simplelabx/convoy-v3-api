require "rails_helper"

# API-ISSUES #5 / #2 (Driver app): every sample account in .api-documents/driver/README.md has its story from the day
# the seed runs, and keeps it on later days (rules the daily job extends, not rows dated on the first seed).
RSpec.describe "Driver app sample accounts seed" do
  # The seeds are not request code: Bullet would flag their loops.
  around do |ex|
    Bullet.enable = false
    ex.run
  ensure
    Bullet.enable = true
  end

  let(:company) { Company.find_by!(code: "SD") }
  let(:driver) { ->(phone) { Driver.find_by!(phone:) } }
  let(:runs) do
    lambda do |member, on|
      DriverApp::Runs.scope(member).where(date: on).includes(:trip, :school_route).order(:starts_at).to_a
                     .map { [ it.start_time_hm, it.kind, it.school_route&.label, DriverApp::Runs.status(it, member) ] }
    end
  end

  def seed_on(time)
    travel_to(time) { Rails.application.load_seed }
  end

  it "gives each sample account its runs from today, on a fresh database and on a later day" do
    seed_on(Time.zone.local(2026, 11, 18, 5, 0)) # a Wednesday in term time, before the first run

    travel_to(Time.zone.local(2026, 11, 18, 5, 0)) do
      ActsAsTenant.with_tenant(company) do
        eric, frankie = driver.("+6592104100"), driver.("+6592474471")
        expect(runs.(eric, Date.current)).to include([ "08:00", "disposal", nil, "scheduled" ])
        # the switch tomorrow 12:00: Eric drives Frankie's afternoon transfer, then both go back to their own bus
        expect(DriverApp::Vehicles.switches(eric).map { [ it[:vehicle].plate, it[:starts_at] ] })
          .to eq([ [ "PC7939R", Time.zone.local(2026, 11, 19, 12, 0) ] ])
        expect(runs.(eric, Date.current + 1)).to eq([ [ "08:00", "disposal", nil, "scheduled" ], [ "14:00", "ad_hoc", nil, "scheduled" ] ])
        expect(runs.(frankie, Date.current + 1)).to be_empty
        expect(runs.(eric, Date.current + 2).map(&:second)).to eq(%w[disposal])
        expect(runs.(frankie, Date.current + 2).map(&:second)).to eq(%w[ad_hoc])

        expect(runs.(driver.("+6592844842"), Date.current).map(&:third)).to eq([ "AM 2", "PM 2" ]) # Ah Beng
        expect(runs.(driver.("+6590023344"), Date.current).map(&:second)).to include("school_run", "corporate_shuttle") # Lee Kok Wah

        siti = driver.("+6590034455")
        expect(runs.(siti, Date.current).first).to eq([ "06:30", "school_route", "AM 1", "scheduled" ])
        yesterday = TripOccurrence.where(driver: siti, date: Date.current - 1).order(:start_time)
        expect(yesterday.pluck(:driver_end).compact).to eq(%w[completed forced skipped])

        kumar = driver.("+6590012233")
        expect(DriverApp::Runs.scope(kumar).where(date: Date.current..Date.current + 7).where(starts_at: Time.current..)
                                .order(:starts_at).first.then { DriverApp::Runs.status(it, kumar) }).to eq("replaced")

        expect(Driver.where("invited_at > joined_at")).to be_none
        expect(OperatorDriver.where("invited_at > joined_at")).to be_none
        expect(Occurrences::Verify.call).to be_empty
      end
    end

    # Two days later the daily job has run and the seed runs again: the same story from that day.
    travel_to(Time.zone.local(2026, 11, 19, 1, 0)) { Occurrences::Daily.call }
    travel_to(Time.zone.local(2026, 11, 20, 1, 0)) { Occurrences::Daily.call }
    seed_on(Time.zone.local(2026, 11, 20, 5, 0))
    travel_to(Time.zone.local(2026, 11, 20, 5, 0)) do
      ActsAsTenant.with_tenant(company) do
        eric = driver.("+6592104100")
        expect(DriverApp::Vehicles.current(eric)[:vehicle].plate).to eq("PD997M")
        expect(DriverApp::Vehicles.switches(eric).map { [ it[:vehicle].plate, it[:starts_at] ] })
          .to eq([ [ "PC7939R", Time.zone.local(2026, 11, 21, 12, 0) ] ])
        expect(runs.(eric, Date.current).map(&:second)).to eq(%w[disposal])
        expect(runs.(driver.("+6592844842"), Date.current).map(&:third)).to eq([ "AM 2", "PM 2" ])
        expect(runs.(driver.("+6590034455"), Date.current).first.third).to eq("AM 1")

        kumar = driver.("+6590012233")
        expect(DriverApp::Runs.scope(kumar).where(date: Date.current..Date.current + 7).where(starts_at: Time.current..)
                                .order(:starts_at).first.then { DriverApp::Runs.status(it, kumar) }).to eq("replaced")
        expect(Occurrences::Verify.call).to be_empty
      end
    end
  end
end
