# School Bus › Year Setup › Bus Attendants: which buses need one and who provides them; Save & Lock.
module Api
  module V1
    class SchoolAttendantPoliciesController < BaseController
      # GET /schools/:school_id/bus_attendants
      def show
        school = authorize find_school, :show?
        render json: { data: payload(school) }
      end

      # PUT /schools/:school_id/bus_attendants { needs: statutory | all | selected, sizes: [LARGE_45, …], provided_by: operator | us }
      def update
        school = authorize find_school, :setup?
        raise ApplicationService::Error, "Send needs, sizes or provided_by" unless params.values_at(:needs, :sizes, :provided_by).any?(&:present?)

        SchoolSetup.ensure_unlocked!(school:, section: :attendants)
        SchoolAttendantPolicy.transaction do
          (school.attendant_policy || school.build_attendant_policy).update!(params.permit(:needs, :provided_by, sizes: []))
          SchoolSetup.lock!(school:, section: :attendants, user: current_user)
        end
        render json: { data: payload(school.reload) }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def payload(school)
        policy = school.attendant_policy || school.build_attendant_policy
        lock = SchoolSetup.find(school, nil, :attendants)
        { needs: policy.needs, sizes: policy.needs == "selected" ? policy.sizes : [], provided_by: policy.provided_by, needed_sizes: policy.needed_sizes,
          saved: policy.persisted?, locked: lock && { at: lock.locked_at, by: lock.locked_by&.name },
          bus_types: SchoolBus::BUS_TYPES.map do |k, t|
            rate = school.bus_size_rates.find { it.bus_type == k }
            { key: k, label: t[:label], seats: t[:seats], required_by_law: t[:law], ba_operator: rate&.ba_operator, ba_us: rate&.ba_us }
          end, routes: routes(school) }
      end

      # Routes of the current and scheduled plans: "x of y routes in current plans need a BA with these settings" (the
      # front end counts them against the settings being edited).
      def routes(school)
        SchoolRoute.joins(:plan).merge(school.plans.where(in_use: true).where("school_plans.effective_to IS NULL OR school_plans.effective_to >= ?", Date.current))
                   .order("school_plans.session", :number).pluck(:id, :label, "school_plans.session", :bus_type)
                   .map { |id, label, session, bus_type| { id:, label:, session:, bus_type: } }
      end
    end
  end
end
