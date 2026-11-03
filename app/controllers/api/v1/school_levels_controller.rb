# School Bus › Year Setup › School Levels: the levels (or suggestions from rider data) with rider counts, grades in
# rider data that are not levels, the sections, and Save & Lock.
module Api
  module V1
    class SchoolLevelsController < BaseController
      # GET /schools/:school_id/levels
      def show
        school = authorize find_school, :show?
        render json: { data: SchoolLevels::Page.new(school).call }
      end

      # PUT /schools/:school_id/levels { levels: [{ name, section, final }] } — in order; saves and locks.
      def update
        school = authorize find_school, :setup?
        list = params.permit(levels: %i[name section final]).to_h.deep_symbolize_keys[:levels]
        SchoolLevels::Save.call(school, list, user: current_user)
        render json: { data: SchoolLevels::Page.new(school.reload).call }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
    end
  end
end
