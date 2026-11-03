# School Bus › Year Setup › Bus Service Registration of an academic year: the settings (Convoy OS defaults until saved),
# what scheduling needs, Save, Schedule and Unschedule.
module Api
  module V1
    class SchoolRegistrationsController < BaseController
      # GET /academic_years/:academic_year_id/registration
      def show
        year = find_year
        authorize year.school, :show?
        render json: { data: SchoolRegistrations.present(year.registration || SchoolRegistrations.build(year)) }
      end

      # PUT /academic_years/:academic_year_id/registration — Save Draft, or Save Changes once scheduled.
      def update = save(nil)

      # POST /academic_years/:academic_year_id/registration/schedule { …settings }
      def schedule = save("scheduled")

      # POST /academic_years/:academic_year_id/registration/unschedule — back to draft: messages stop, the form closes.
      def unschedule = save("draft")

      # POST /academic_years/:academic_year_id/registration/release { key } — Release Now for a message sent by hand (welcome with pick-up details).
      def release
        year = find_year
        authorize year.school, :setup?
        reg = year.registration or raise ApplicationService::Error, "Save the registration first"
        msg = reg.messages.find_by!(key: params.require(:key))
        raise ApplicationService::Error, "#{msg.preset[:name]} goes out by itself" unless msg.preset[:manual]
        raise ApplicationService::Error, "#{msg.preset[:name]} is off" unless msg.enabled

        msg.update!(released_at: Time.current)
        render json: { data: SchoolRegistrations.present(reg.reload) }
      end

      private

      def save(status)
        year = find_year
        authorize year.school, :setup?
        reg = SchoolRegistrations::Save.call(year, registration_params, user: current_user, status:)
        render json: { data: SchoolRegistrations.present(reg.reload) }
      end

      def find_year
        AcademicYear.where(school: policy_scope(School)).includes(:terms, :setup_locks, registration: %i[messages saved_by], school: %i[levels policy_versions])
                                  .find(params[:academic_year_id])
      end

      def registration_params
        p = params.permit(*SchoolRegistrations::FIELDS - %i[levels sessions asks], levels: [], sessions: [], asks: [],
                          messages: SchoolRegistrations::MESSAGE_FIELDS).to_h.deep_symbolize_keys
        bool = ActiveModel::Type::Boolean.new
        p[:messages]&.each { |m| %i[enabled email whatsapp app scheduled].each { m[it] = bool.cast(m[it]) if m.key?(it) } }
        p
      end
    end
  end
end
