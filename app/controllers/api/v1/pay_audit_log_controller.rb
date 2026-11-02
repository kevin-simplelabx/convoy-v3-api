# HR > Audit Log: every change to pay, bonuses, points and rewards, with who made it and when (read only).
module Api
  module V1
    class PayAuditLogController < BaseController
      # GET /pay/audit_log?q=&action_type=&item=&page=
      def index
        authorize :pay, :index?
        entries = Pay::AuditLog.call(q: params[:q], action: params[:action_type], item: params[:item])
        pagy, rows = pagy_array(entries)
        render json: { data: rows, meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages,
                                           actions: Pay::AuditLog::ACTIONS, items: Pay::AuditLog::ITEM_LABELS } }
      end
    end
  end
end
