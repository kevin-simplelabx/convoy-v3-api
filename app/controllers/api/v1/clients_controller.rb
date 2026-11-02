# Managed Clients: the list (also the trip form's Client picker), Add / Edit (with the School link), the client record
# page, and Delete (refused while trips are still running or bookings are open).
module Api
  module V1
    class ClientsController < BaseController
      def index
        authorize Client
        scope = policy_scope(Client).kept.ransack(ransack_params).result.order(:name)
        render_page scope, ClientBlueprint, users_count: ClientUser.kept.group(:client_id).count
      end

      def show
        client = authorize policy_scope(Client).kept.includes(DETAIL).find(params[:id])
        render_data client, ClientBlueprint, view: :full
      end

      def create
        authorize Client
        render_data Clients::Save.call(params: client_params), ClientBlueprint, view: :full, status: :created
      end

      def update
        client = authorize find_client
        render_data Clients::Save.call(client:, params: client_params), ClientBlueprint, view: :full
      end

      # PUT /clients/:id/bookable_vehicle_types { vehicle_type_ids: [] } — Bookable Vehicles; [] = All Vehicle Types.
      def bookable_vehicle_types
        client = authorize find_client, :update?
        ids = Array(params[:vehicle_type_ids]).compact_blank.map(&:to_i).uniq
        offered = VehicleType.enabled_for(current_company).where(id: ids).pluck(:id)
        raise ApplicationService::Error, "Pick vehicle types you offer" if offered.size != ids.size

        Client.transaction do
          client.bookable_vehicle_types.where.not(vehicle_type_id: ids).delete_all
          (ids - client.bookable_vehicle_types.pluck(:vehicle_type_id)).each { |id| client.bookable_vehicle_types.create!(vehicle_type_id: id) }
        end
        render_data policy_scope(Client).includes(DETAIL).find(client.id), ClientBlueprint, view: :full
      end

      def destroy
        client = authorize find_client
        blockers = client.delete_blockers
        if blockers.any?
          return render_error(:unprocessable_content, "#{client.name} has #{blockers.to_sentence}. End or delete them first")
        end

        client.discard!
        head :no_content
      end

      private

      DETAIL = [ :end_customers, :bookable_vehicle_types, { sites: %i[school billing_contacts], pickup_points: :created_by, school: :calendar } ].freeze

      def find_client = policy_scope(Client).kept.find(params[:id])

      def client_params
        params.expect(client: %i[kind name uen contact_name phone email billing_address on_time_allowance school_id school_calendar_id])
      end
    end
  end
end
