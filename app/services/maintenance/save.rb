# Plan the Visit / Record the Work (maintenance dialog on the Scheduler and Fleet > Maintenance).
# A workshop typed by name (New Workshop) is matched or created. status "completed" records who and when.
# An invoice (upload or a finished document read) is attached; what Claude read fills the empty workshop, address,
# odometer and, when there are none yet, the line items.
module Maintenance
  class Save < ApplicationService
    Result = Data.define(:visit, :filled, :warnings)

    def initialize(visit:, attributes:, user:, workshop_name: nil, workshop_address: nil, invoice: nil, document_read: nil)
      @visit = visit
      @attrs = attributes
      @user = user
      @workshop_name = workshop_name
      @workshop_address = workshop_address
      @invoice = invoice
      @read = document_read
    end

    def call
      MaintenanceVisit.transaction do
        @visit.assign_attributes(@attrs)
        @visit.created_by ||= @user
        @visit.workshop = Workshop.named(@workshop_name).tap { |w| w.address ||= @workshop_address; w.save! } if @workshop_name.present?
        filled = from_invoice
        if @visit.completed? && (@visit.new_record? || @visit.status_changed?)
          @visit.completed_by = @user
          @visit.completed_at = Time.current
        end
        @visit.save!
        attach_invoice
        Result.new(@visit, filled, warnings)
      end
    end

    private

    def from_invoice
      return [] unless @read&.done?
      raise Error, "That read was for a #{@read.kind.humanize.downcase}" unless @read.kind == "maintenance_invoice"

      v = @read.data
      filled = []
      if @visit.workshop.nil? && v[:workshop]
        @visit.workshop = Workshop.named(v[:workshop]).tap { |w| w.address ||= v[:address]; w.save! }
        filled << "workshop"
      end
      { address: :address, odometer: :odometer }.each do |field, key|
        next if @visit.public_send(field).present? || v[key].blank?

        @visit.public_send(:"#{field}=", v[key])
        filled << field.to_s
      end
      if @visit.lines.reject(&:marked_for_destruction?).empty? && v[:lines].present?
        v[:lines].each_with_index { |l, i| @visit.lines.build(l.merge(position: i)) }
        filled << "lines"
      end
      @visit.gst_on = v[:gst] unless v[:gst].nil?
      @plate_read = v[:plate]
      filled
    end

    def attach_invoice
      file = @invoice.presence || (@read&.file.present? ? @read.file_copy : nil)
      @visit.invoices.create!(file:) if file
    end

    def warnings
      list = []
      list << "The invoice is for #{@plate_read}, not #{@visit.vehicle.plate}" if @plate_read && @plate_read != @visit.vehicle.plate
      last = @visit.last_odometer
      list << "The odometer is lower than the last reading (#{last} km)" if last && @visit.odometer && @visit.odometer < last
      list
    end
  end
end
