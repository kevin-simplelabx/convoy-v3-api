# Runs That Move Together (trip drawer): group run slots, or ungroup.
module Api
  module V1
    class TripRunGroupsController < BaseController
      before_action :set_trip

      # POST /trips/:trip_id/run_groups { slots: ["d1r0|1", "d1r1|1"] } — the slots leave any group they were in.
      def create
        authorize TripRunGroup
        runs = @trip.runs.index_by(&:key)
        slots = Array(params.require(:slots)).map do |key|
          run_key, n = key.split("|")
          runs.fetch(run_key) { raise ApplicationService::Error, "No run #{run_key}" }.slots.find_or_create_by!(slot_no: n.to_i)
        end
        raise ApplicationService::Error, "Pick two or more runs" if slots.size < 2

        group = TripRunGroup.transaction do
          old = slots.filter_map(&:trip_run_group_id).uniq
          @trip.run_groups.create!.tap do |g|
            TripRunSlot.where(id: slots.map(&:id)).update_all(trip_run_group_id: g.id)
            @trip.run_groups.where(id: old).find_each { |o| o.destroy! if o.slots.count < 2 }
          end
        end
        render json: { data: { group_key: "g#{group.id}", slots: params[:slots] } }, status: :created
      end

      def destroy
        authorize(@trip.run_groups.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_trip
        @trip = Trip.kept.includes(runs: :slots).find(params[:trip_id])
      end
    end
  end
end
