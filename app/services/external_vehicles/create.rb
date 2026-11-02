# New External Vehicle (Scheduler and External Vehicles): the bus, its driver and the company it is hired from.
# The company is matched by name (created when new, phone and PayNow updated); a new vehicle must fit
# under the company's external vehicle cap. Passing vehicle_id edits that external vehicle instead.
# Company fields (phone, paynow_uen, cost_per_trip, cost_per_day, valid_until) apply to every bus of the company.
# Review and Add passes submission_id: the driver's answer is marked added and the bus marked as from the Share Form.
module ExternalVehicles
  class Create < ApplicationService
    COMPANY_FIELDS = %i[phone paynow_uen cost_per_trip cost_per_day valid_until].freeze

    def initialize(params:, company:, user: nil)
      @params = params
      @company = company
      @user = user
    end

    def call
      plate = @params[:plate].to_s.strip
      name = @params.dig(:company, :name).to_s.strip
      raise Error, "Enter the licence plate" if plate.blank?
      raise Error, "Enter the company the bus is hired from" if name.blank?

      Vehicle.transaction do
        vehicle = @params[:vehicle_id].present? ? Vehicle.external.kept.find(@params[:vehicle_id]) : new_vehicle
        operator = Operator.external_named(name)
        operator.assign_attributes(@params.fetch(:company, {}).slice(*COMPANY_FIELDS).compact_blank)
        operator.save!
        vehicle.update!(plate:, seats: @params[:seats].presence, driver_name: @params[:driver_name],
                        driver_phone: @params[:driver_phone], operator:)
        take_submission(vehicle)
        vehicle
      end
    end

    private

    def take_submission(vehicle)
      return if @params[:submission_id].blank?

      submission = ExternalVehicleSubmission.pending.find(@params[:submission_id])
      submission.decide!(:added, user: @user, vehicle:)
      vehicle.update!(source: "share_form")
    end

    def new_vehicle
      cap = @company.external_vehicle_cap
      if Vehicle.external.kept.count >= cap
        raise Error, "All #{cap} external vehicle slots are used. Remove one in External Vehicles, or ask Convoy to raise the limit"
      end

      Vehicle.new(tags: [ "External" ])
    end
  end
end
