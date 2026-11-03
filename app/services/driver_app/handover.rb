# Switch Vehicle (the handover inspection, decided 26/10/2026 § 3.9): before taking over a bus, the driver photographs
# all six sides (Front, Left side, Right side, Back, Odometer, Inside; a photo can be marked up) and signs the
# declaration. The bus is the driver's now or later today / tomorrow (the schedule the office set); the runs already
# follow that schedule. Sent once per client_id. Returns [handover, replayed].
module DriverApp
  class Handover < ApplicationService
    def initialize(account:, member:, params:)
      @account = account
      @member = member
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      client_id = @params[:client_id].to_s.downcase
      raise Error.new("Send a client_id (UUID)", details: { client_id: [ "must be a UUID" ] }) unless client_id.match?(Drive::UUID)

      done = VehicleHandover.find_by(driver_account_id: @account.id, client_id:)
      return [ done, true ] if done

      vehicle, schedule = vehicle!
      photos = @params[:photos] || {}
      missing = VehicleHandover::SIDES.reject { photos[it.to_sym].present? }
      raise Error.new("Take all 6 photos", code: "photos_needed", details: { missing: }) if missing.any?
      raise Error.new("Tick the declaration", code: "declaration_needed") unless ActiveModel::Type::Boolean.new.cast(@params[:declaration])

      at = @params[:at].presence ? [ Time.zone.iso8601(@params[:at].to_s), Time.current ].min : Time.current
      handover = VehicleHandover.transaction do
        h = VehicleHandover.create!(company_id: vehicle.company_id, vehicle:, driver_account: @account, vehicle_driver_schedule: schedule,
                                    @member.model_name.singular => @member, client_id:, at:, declared_at: Time.current, note: @params[:note].presence)
        VehicleHandover::SIDES.each do |side|
          h.photos.create!(side:, photo: photos[side.to_sym], marked_photo: @params.dig(:marked, side.to_sym).presence, marks: marks(side))
        end
        h
      end
      [ handover, false ]
    rescue ArgumentError
      raise Error.new("at must be an ISO 8601 time", details: { at: [ "is not a time" ] })
    end

    private

    # The bus the driver is on now, or one they take over later (today or tomorrow).
    def vehicle!
      id = @params[:vehicle_id].to_i
      current = Vehicles.current(@member)
      return [ current[:vehicle], current[:schedule] ] if current && current[:vehicle].id == id

      switch = Vehicles.switches(@member).find { it[:vehicle].id == id }
      raise Error.new("This bus is not yours today", code: "not_your_bus") unless switch

      [ switch[:vehicle], switch[:schedule] ]
    end

    def marks(side)
      value = @params.dig(:marks, side.to_sym)
      value = JSON.parse(value) if value.is_a?(String)
      Array(value)
    rescue JSON::ParserError
      []
    end
  end
end
