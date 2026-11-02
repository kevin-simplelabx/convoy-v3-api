# HR > Salary Simulator: work out a made-up month (nothing is saved), Fill Sample Month, and the five shared templates.
module Api
  module V1
    class PaySimulatorController < BaseController
      # POST /pay/simulate { scheme_id, vehicle_type_id, month: "2026-11", jobs: { "2026-11-03": [...] }, routes: [...],
      #                      school_holidays: { from, to }, rejected, on_time_percent, attendance_percent }
      def simulate
        authorize :pay, :show?
        scheme = PayScheme.kept.includes(:route_bands, :volume_tiers, :target_tiers, rate_plan: { periods: %i[ranges rates] }).find(params.require(:scheme_id))
        out = Pay::Simulation.call(scheme:, vehicle_type_id: params[:vehicle_type_id]&.to_i, month:, jobs: jobs_param, routes: routes_param,
                                   school_holidays:, rejected: params[:rejected].to_i, on_time: params[:on_time_percent].presence&.to_d,
                                   attendance: params[:attendance_percent].presence&.to_d)
        render json: { data: PaySimulationBlueprint.render_as_hash(out) }
      end

      # GET /pay/simulate/sample?month=2026-11
      def sample
        authorize :pay, :show?
        render json: { data: { month: month.strftime("%Y-%m"), jobs: Pay::Simulation.sample(month) } }
      end

      def templates
        authorize :pay, :show?
        saved = PaySimulatorTemplate.includes(:saved_by).index_by(&:slot)
        render json: { data: PaySimulatorTemplate::SLOTS.map { |slot| { slot:, template: saved[slot]&.then { |t| template_json(t) } } } }
      end

      # PUT /pay/simulator_templates/:slot { template: { name, description, month, pay_scheme_id, vehicle_type_id, rejected,
      #   on_time_percent, attendance_percent, school_holidays_from, school_holidays_to, routes: [], jobs: {} } }
      def save_template
        authorize :pay, :show?
        t = PaySimulatorTemplate.find_or_initialize_by(slot: params[:slot].to_i)
        attrs = params.expect(template: %i[name description month pay_scheme_id vehicle_type_id rejected on_time_percent attendance_percent
                                           school_holidays_from school_holidays_to])
        month = Date.parse("#{attrs[:month]}-01") rescue nil # rubocop:disable Style/RescueModifier
        t.update!(attrs.merge(month:, routes: routes_param(:template), jobs: params.dig(:template, :jobs)&.to_unsafe_h || {}, saved_by: current_user))
        render json: { data: template_json(t) }
      end

      def delete_template
        authorize :pay, :show?
        PaySimulatorTemplate.find_by!(slot: params[:slot].to_i).destroy!
        head :no_content
      end

      private

      def month
        Date.strptime(params[:month].presence || Date.current.strftime("%Y-%m"), "%Y-%m")
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-11"
      end

      def jobs_param = params[:jobs].respond_to?(:to_unsafe_h) ? params[:jobs].to_unsafe_h : {}

      def routes_param(root = nil)
        list = root ? params.dig(root, :routes) : params[:routes]
        Array(list).map { |r| { name: r[:name].to_s, minutes: r[:minutes].to_i, start: r[:start_time].to_s } }
      end

      def school_holidays
        from = params.dig(:school_holidays, :from).presence
        return nil unless from

        Date.parse(from)..Date.parse(params.dig(:school_holidays, :to).presence || from)
      end

      def template_json(t)
        t.slice(:slot, :name, :description, :pay_scheme_id, :vehicle_type_id, :rejected, :on_time_percent, :attendance_percent,
                :school_holidays_from, :school_holidays_to, :routes, :jobs, :updated_at)
         .merge(month: t.month.strftime("%Y-%m"), saved_by: t.saved_by && { id: t.saved_by.id, name: t.saved_by.shown_name },
                days_with_jobs: t.jobs.count { |_d, l| Array(l).any? })
      end
    end
  end
end
