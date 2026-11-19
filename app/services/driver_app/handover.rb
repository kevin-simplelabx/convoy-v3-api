# Switch Vehicle (the handover inspection, decided 26/10/2026 § 3.9): before taking over a bus, the driver photographs
# all six sides (Front, Left side, Right side, Back, Odometer, Inside; a photo can be marked up), may add photos of
# anything to highlight (each marked up too) with a note, and signs the declaration. The bus is the driver's now or later today / tomorrow (the schedule the office set); the runs already
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

      highlights = self.highlights

      at = @params[:at].presence ? [ Time.zone.iso8601(@params[:at].to_s), Time.current ].min : Time.current
      handover = VehicleHandover.transaction do
        h = VehicleHandover.create!(company_id: vehicle.company_id, vehicle:, driver_account: @account, vehicle_driver_schedule: schedule,
                                    @member.model_name.singular => @member, client_id:, at:, declared_at: Time.current, note: @params[:note].presence)
        VehicleHandover::SIDES.each do |side|
          h.photos.create!(side:, photo: photos[side.to_sym], marked_photo: @params.dig(:marked, side.to_sym).presence, marks: marks(side))
        end
        highlights.each do |hl|
          h.photos.create!(side: VehicleHandover::HIGHLIGHT, photo: hl[:photo], marked_photo: hl[:marked].presence, marks: shapes(hl[:marks]))
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

    def marks(side) = shapes(@params.dig(:marks, side.to_sym))

    def shapes(value)
      value = JSON.parse(value) if value.is_a?(String)
      Array(value)
    rescue JSON::ParserError
      []
    end

    # highlights[0][photo], highlights[0][marked], highlights[0][marks] (multipart sends a hash keyed by index).
    def highlights
      list = @params[:highlights]
      list = list.sort_by { |k, _| k.to_s.to_i }.map(&:last) if list.is_a?(Hash)
      list = Array(list)
      max = VehicleHandover::MAX_HIGHLIGHTS
      raise Error.new("Add #{max} highlight photos at most", details: { highlights: [ "too many (#{max} at most)" ] }) if list.size > max
      raise Error.new("Each highlight needs a photo", details: { highlights: [ "photo is missing" ] }) if list.any? { it.is_a?(Hash) ? it[:photo].blank? : true }

      list
    end
  end
end
