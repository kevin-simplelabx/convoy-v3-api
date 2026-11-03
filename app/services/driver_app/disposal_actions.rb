# Disposal driving actions (part of DriverApp::Drive, same client_id and at rules). After Start and Arrive at the
# meeting point:
#   disposal_start      start odometer (+ dash photo); start: agreed (default) or now (only before the agreed time, when
#                       the coordinator asked to start early); a late coordinator does not move the block
#   disposal_run_start  a run the coordinator directs (the road where it starts)
#   disposal_run_end    the run is over (the road, passengers when the trip counts them)
#   disposal_extend     the block's extension, in 30-minute steps (the client signs with their name; the driver confirms
#                       operations was told)
#   disposal_end        end odometer (+ photo), released by, an optional signature (needs the name): the trip ends
module DriverApp
  module DisposalActions
    Error = ApplicationService::Error
    STEP = 30

    def disposal_start
      disposal_trip!
      started!
      raise Error.new("The disposal has started", code: "started") if @occ.disposal

      first = points.reject { it[:waypoint] }.first
      event = event_for(first)
      raise Error.new("Arrive at #{first[:name]} first", code: "not_arrived") unless event.arrived_at

      agreed = @occ.starts_at
      early = @params[:start].to_s == "now" && @at < agreed
      @occ.create_disposal!(company_id: @occ.company_id, booked_minutes: (@occ.trip.hours.to_f * 60).round, block_starts_at: early ? @at : agreed,
                            started_at: @at, early_start: early, late_minutes: [ ((@at - agreed) / 60).floor, 0 ].max,
                            start_odometer: odometer(:start_odometer), start_photo: @params[:start_photo].presence)
      event.update!(departed_at: event.departed_at || @at, source: "driver_app")
    end

    def disposal_run_start
      disposal = open_disposal!
      raise Error, "A run is on: end it first" if disposal.runs.any?(&:open?)

      disposal.runs.create!(started_at: @at, from_road: road(:from_road), from_lat: @params[:lat], from_lng: @params[:lng])
    end

    def disposal_run_end
      run = open_disposal!.runs.find(&:open?) or raise Error, "No run is on"
      run.update!(ended_at: @at, to_road: road(:to_road), to_lat: @params[:lat], to_lng: @params[:lng],
                  pax: @params.key?(:pax) ? count_param(:pax) : run.pax)
    end

    # minutes: the new total extension (0, 30, 60…).
    def disposal_extend
      disposal = open_disposal!
      minutes = Integer(@params[:minutes].to_s, exception: false)
      raise Error.new("Extend in steps of #{STEP} minutes", details: { minutes: [ "must be 0, 30, 60…" ] }) unless minutes && minutes >= 0 && (minutes % STEP).zero?
      raise Error, "Add or remove time first" if minutes == disposal.extension_minutes
      raise Error.new("Confirm that operations was told", code: "tell_operations") unless ActiveModel::Type::Boolean.new.cast(@params[:operations_told])

      name = @params[:signed_by].to_s.squish
      raise Error.new("The client signs with their name", details: { signed_by: [ "can't be blank" ] }) if name.length < 2

      disposal.extensions.create!(at: @at, from_minutes: disposal.extension_minutes, to_minutes: minutes, signed_by: name,
                                  signature: @params[:signature].presence, operations_told: true)
      disposal.update!(extension_minutes: minutes)
    end

    def disposal_end
      disposal = open_disposal!
      name = @params[:released_by].to_s.squish.presence
      raise Error.new("A signature needs the name of who released the bus", details: { released_by: [ "can't be blank" ] }) if @params[:release_signature].present? && name.nil?

      disposal.runs.select(&:open?).each { it.update!(ended_at: @at) }
      disposal.assign_attributes(ended_at: @at, end_odometer: odometer(:end_odometer), end_photo: @params[:end_photo].presence,
                                 released_by: name, release_signature: @params[:release_signature].presence)
      figures = disposal.figures(@at)
      disposal.update!(used_minutes: figures[:used_minutes], overtime_minutes: figures[:overtime_minutes], km: disposal.end_odometer - disposal.start_odometer)

      last = points.reject { it[:waypoint] }.last
      event = event_for(last)
      event.update!(arrived_at: event.arrived_at || @at, departed_at: event.departed_at || @at, source: "driver_app")
      used = figures[:used_minutes]
      feedback(@params[:feedback].presence || "Disposal #{used / 60}h #{used % 60}m, #{disposal.km} km, released by #{name || 'Not recorded'}")
      Occurrences::DriverProgress.call(@occ, :end, at: @at)
      @occ.update_columns(driver_end: "completed", end_on_board: 0) # rubocop:disable Rails/SkipsModelValidations
    end

    private

    def disposal_trip!
      raise Error.new("This trip is not a disposal", code: "not_disposal") unless @occ.kind == "disposal"
    end

    def open_disposal!
      disposal_trip!
      disposal = @occ.disposal or raise Error.new("Start the disposal first", code: "disposal_not_started")
      raise Error.new("The disposal has ended", code: "ended") if disposal.ended?

      disposal
    end

    def odometer(key)
      value = Integer(@params[key].to_s.delete(",").presence || "", exception: false)
      raise Error.new("Type the odometer reading", details: { key => [ "must be a whole number" ] }) unless value&.positive?

      value
    end

    def road(key) = @params[key].to_s.squish.truncate(120).presence
  end
end
