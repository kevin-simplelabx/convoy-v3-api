# Client Portal › Notices (read only; sending your own is not built): notices to riders of the client's trips that are in
# force or scheduled, for the trips the person covers (a trip with no site: people covering every site).
module Portal
  class Notices < ApplicationService
    def initialize(client_user:, now: Time.current)
      @user = client_user
      @now = now
    end

    def self.trips_for(user) = user.limit_to_sites(Trip.kept.where(client_id: user.client_id))

    def call
      Notice.where(audience: "trip", trip_id: self.class.trips_for(@user).select(:id), ended_at: nil).where("ends_at > ?", @now)
            .includes(:trip).order(:starts_at).map do |n|
        { id: n.id, message: n.message, starts_at: n.starts_at, ends_at: n.ends_at, state: n.starts_at <= @now ? "in_force" : "scheduled",
          channels: { banner: n.banner, push: n.push, sms: n.sms }, trip: { id: n.trip.id, title: n.trip.title } }
      end
    end
  end
end
