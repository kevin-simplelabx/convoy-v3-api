# School Bus › Year Setup › Payment & Refund Policy of a school: every version (Scheduled / In Use / Replaced), the
# draft to start a new version from, and Publish. Also the school's collection cycle and who pays (from this year's fares).
module Api
  module V1
    class SchoolPoliciesController < BaseController
      # GET /schools/:school_id/policy
      def show
        school = authorize find_school, :show?
        render json: { data: payload(school) }
      end

      # POST /schools/:school_id/policy { effective_on, …fields, reminders: [...] } — publish a version.
      def create
        school = authorize find_school, :money_setup?
        Policies::Publish.call(school, policy_params, user: current_user)
        render json: { data: payload(school.reload) }, status: :created
      end

      private

      def find_school = policy_scope(School).includes(policy_versions: %i[reminders published_by]).find(params[:school_id])

      def payload(school)
        versions = school.policy_versions.to_a
        today = Date.current
        scheduled = versions.select { it.effective_on > today }.min_by(&:effective_on)
        current = SchoolPolicyVersion.current_for(versions, today)
        base = scheduled || current
        year = AcademicYear.default_for(school, today)
        fares = year&.fare_table
        {
          versions: versions.sort_by { [ -it.effective_on.jd, -it.version ] }.map do |v|
            { version: v.version, effective_on: v.effective_on, state: v.state(versions, today), published_by: v.published_by&.name, published_at: v.created_at }
          end,
          current: current && Policies.present(current).merge(version: current.version, effective_on: current.effective_on),
          scheduled: scheduled && Policies.present(scheduled).merge(version: scheduled.version, effective_on: scheduled.effective_on),
          draft: (base ? Policies.present(base) : Policies.default).merge(effective_on: scheduled&.effective_on || today),
          collection: fares && { year: year.key, cycle: fares.cycle, months: fares.months, payer: fares.payer, bill_to_name: fares.bill_to_name,
                                 bill_to_email: fares.bill_to_email }
        }
      end

      def policy_params
        bools = %i[ack_required ack_reaccept]
        p = params.permit(:effective_on, *Policies::FIELDS, reminders: Policies::REMINDER_FIELDS).to_h.deep_symbolize_keys
        cast = ->(v) { ActiveModel::Type::Boolean.new.cast(v) || false }
        bools.each { p[it] = cast.(p[it]) if p.key?(it) }
        p[:reminders] = Array(p[:reminders]).map { |r| r.merge(%i[email whatsapp app].to_h { [ it, cast.(r[it]) ] }) }
        p
      end
    end
  end
end
