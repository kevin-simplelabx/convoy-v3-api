# Add Entry / Save Entry (Fuel & Energy). A receipt (upload or a finished fuel_receipt read) is attached; what Claude
# read fills the empty fields: kind, date, time, quantity, cost, odometer, station, the company (matched in Fuel
# Companies) and the vehicle (by plate, own buses). Then the vehicle's derived columns and Needs a Look are worked out
# again.
# Result: entry, filled (fields filled from the receipt), warnings (plate differs, company not listed, odometer back).
module FuelEntries
  class Save < ApplicationService
    Result = Data.define(:entry, :filled, :warnings)
    FILLABLE = %i[kind date time quantity cost odometer station].freeze

    def initialize(entry:, attributes:, user:, receipt: nil, document_read: nil)
      @entry = entry
      @attrs = attributes
      @user = user
      @receipt = receipt
      @read = document_read
      @warnings = []
    end

    def call
      old_vehicle = @entry.vehicle
      FuelEntry.transaction do
        @entry.assign_attributes(@attrs)
        @entry.created_by ||= @user
        filled = from_receipt
        @entry.receipt = @receipt if @receipt.present?
        @entry.save!
        [ old_vehicle, @entry.vehicle ].compact.uniq.each { |v| Recompute.call(vehicle: v) }
        FuelAlerts::Scan.call
        @entry.reload
        odometer_warning
        Result.new(@entry, filled, @warnings)
      end
    end

    private

    def from_receipt
      return [] unless @read&.done?
      raise Error, "That read was for a #{@read.kind.humanize.downcase}" unless @read.kind == "fuel_receipt"

      v = @read.data
      @entry.document_read = @read
      @entry.receipt = @read.file_copy if @receipt.blank? && @read.file.present? && @entry.receipt.blank?
      filled = FILLABLE.select do |field|
        next false if v[field].blank? || @entry.public_send(field).present?

        @entry.public_send(:"#{field}=", v[field])
        true
      end.map(&:to_s)
      filled += match_company(v[:brand], v[:station]) + match_vehicle(v[:plate])
      filled
    end

    def match_company(brand, station)
      return [] if brand.blank? || @entry.fuel_company

      company = FuelCompany.named_in(brand)
      unless company
        @warnings << "The company on the receipt, #{brand}, is not in the list. Add it in Fuel Companies"
        return []
      end
      @entry.fuel_company = company
      @entry.station = @entry.station.to_s.sub(/\A#{Regexp.escape(company.name)}[\s,|-]*/i, "").presence if @entry.station
      [ "fuel_company" ]
    end

    def match_vehicle(plate)
      return [] if plate.blank?

      if @entry.vehicle
        @warnings << "The receipt shows #{plate}, but the vehicle picked is #{@entry.vehicle.plate}" if @entry.vehicle.plate != plate
        return []
      end
      vehicle = Vehicle.kept.own.find_by(plate:)
      vehicle ? (@entry.vehicle = vehicle; [ "vehicle" ]) : []
    end

    def odometer_warning
      return unless @entry.odometer_back

      @warnings << "The odometer is lower than the last reading of #{@entry.odometer_back} km. Check the number"
    end
  end
end
