# HR > Drivers: own active drivers with the pay scheme and vehicle type used to work out their pay, and their dated
# assignments (Assign Scheme / Assign Vehicle Type, change dates or the scheme / type, remove). Each change saves at once.
module Api
  module V1
    class PayDriversController < BaseController
      KINDS = { "schemes" => [ DriverPayScheme, :pay_scheme_id ], "vehicle_types" => [ DriverVehicleType, :vehicle_type_id ] }.freeze

      def index
        authorize :pay, :index?
        drivers = Driver.kept.active.includes(:kyc_profile).order(:name)
        drivers = drivers.where("drivers.name ILIKE ?", "%#{Driver.sanitize_sql_like(params[:q].to_s.strip)}%") if params[:q].present?
        render json: { data: PayDriverBlueprint.render_as_hash(Pay::DriverList.call(drivers:)) }
      end

      def show
        authorize :pay, :show?
        render_driver find_driver
      end

      # POST /pay/drivers/:id/schemes { assignment: { pay_scheme_id, starts_on, ends_on } } (also /vehicle_types with vehicle_type_id)
      def create_assignment
        authorize :pay, :update?
        driver = find_driver
        model, key = KINDS.fetch(params[:kind])
        model.transaction do
          model.create!(assignment_params(key).merge(driver:, company_id: driver.company_id))
          model.recut!(driver.id)
        end
        render_driver driver, status: :created
      end

      # PATCH /pay/drivers/:id/schemes/:assignment_id
      def update_assignment
        authorize :pay, :update?
        driver = find_driver
        model, key = KINDS.fetch(params[:kind])
        model.transaction do
          model.where(driver:).find(params[:assignment_id]).update!(assignment_params(key))
          model.recut!(driver.id)
        end
        render_driver driver
      end

      def destroy_assignment
        authorize :pay, :update?
        driver = find_driver
        model, = KINDS.fetch(params[:kind])
        model.where(driver:).find(params[:assignment_id]).destroy!
        render_driver driver
      end

      private

      def find_driver = Driver.kept.find(params[:id])

      def assignment_params(key) = params.expect(assignment: [ key, :starts_on, :ends_on ])

      def render_driver(driver, status: :ok)
        driver = Driver.includes(:kyc_profile, pay_schemes: :pay_scheme, pay_vehicle_types: :vehicle_type).find(driver.id)
        render json: { data: PayDriverBlueprint.render_as_hash(Pay::DriverList.call(drivers: [ driver ]).first, view: :detail) }, status:
      end
    end
  end
end
