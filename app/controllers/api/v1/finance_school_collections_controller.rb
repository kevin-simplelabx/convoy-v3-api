# Finance › School Bus Collections: the School Bus bills of every school the user may open, with totals and a line per
# school; each bill opens in its school's Collections.
module Api
  module V1
    class FinanceSchoolCollectionsController < BaseController
      # GET /finance/school_collections?school_id=&status=&q=
      def index
        authorize :finance, :index?
        all = policy_scope(School).order(:name).to_a
        schools = params[:school_id].present? ? all.select { it.id == params[:school_id].to_i } : all
        out = SchoolBills::Company.call(schools, status: params[:status], q: params[:q])
        render json: { data: out[:rows], meta: out.except(:rows).merge(shown: out[:rows].size, schools: all.map { { id: it.id, name: it.name } }) }
      end
    end
  end
end
