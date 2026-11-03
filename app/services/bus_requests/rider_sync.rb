# Daily: a confirmed change of service or address whose date has come is carried onto the rider record, once (the route
# plans already have it); renewed riders move to the level asked for once their new year has started.
module BusRequests
  class RiderSync < ApplicationService
    def initialize(today: Date.current)
      @today = today
    end

    def call
      reqs = BusRequest.where(kind: %w[svc adr], status: "Active", rider_patched_on: nil).where(effective_on: ..@today)
                       .where.not(school_rider_id: nil).includes(:school_rider, :events)
      reqs.each { patch(it) }
      BusRequest.where(kind: "new", renew: true, status: "Active", level_moved_on: nil).where(start_on: ..@today).where.not(level: nil)
                .where.not(school_rider_id: nil).includes(:school_rider, :events).find_each do |r|
        r.school_rider.update!(grade: r.level)
        r.update!(level_moved_on: @today)
        r.log!("Moved to #{r.level} for the new year", by: "Convoy")
      end
    end

    private

    def patch(r)
      rider = r.school_rider
      if r.kind == "svc"
        attrs = { am: r.am, pm: r.pm }
        attrs[:cca_days] = r.cca ? r.cca_days.presence || rider.cca_days : [] if r.cca != !!r.old_cca
        rider.update!(attrs)
        text = "Rider record now #{[ ('AM' if r.am), ('PM' if r.pm), ('CCA' if r.cca) ].compact.join(' + ').presence || 'no sessions'} from #{fmt(r.effective_on)}"
      else
        rider.update!(address: r.address, postal: r.postal.to_s.gsub(/\D/, ""), lat: r.lat || rider.lat, lng: r.lng || rider.lng)
        text = "Rider record moved to #{r.address.presence || r.postal} from #{fmt(r.effective_on)}"
      end
      r.update!(rider_patched_on: @today)
      r.log!(text, by: "Convoy")
    end

    def fmt(d) = d.strftime("%d/%m/%Y")
  end
end
