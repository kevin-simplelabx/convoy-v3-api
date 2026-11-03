# Every error leaves the API as { error: { code, message, details } } with the matching HTTP status.
module ErrorHandling
  extend ActiveSupport::Concern

  class Unauthenticated < StandardError; end

  included do
    rescue_from StandardError, with: :render_internal_error unless Rails.env.local?
    rescue_from Unauthenticated, with: -> { render_error(:unauthorized, "Sign in to continue") }
    rescue_from ActiveRecord::RecordNotFound, with: -> { render_error(:not_found, "Not found") }
    rescue_from ActiveRecord::RecordInvalid, with: ->(e) { render_invalid(e.record) }
    rescue_from ActiveRecord::RecordNotDestroyed, with: ->(e) { render_invalid(e.record) }
    rescue_from ActiveRecord::StaleObjectError,
                with: -> { render_error(:conflict, "Someone else changed this just now. Reload and try again") }
    rescue_from ActionController::ParameterMissing, with: ->(e) { render_error(:bad_request, e.message) }
    rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    rescue_from ApplicationService::Error, with: ->(e) { render_error(:unprocessable_content, e.message, code: e.code || "invalid", details: e.details) }
    rescue_from ActsAsTenant::Errors::NoTenantSet, with: -> { render_error(:unprocessable_content, "Pick a company first") }
  end

  private

  def render_error(status, message, details: nil, code: nil)
    body = { code: code || Rack::Utils::SYMBOL_TO_STATUS_CODE.key(Rack::Utils.status_code(status)).to_s, message: }
    body[:details] = details if details
    render json: { error: body }, status:
  end

  def render_invalid(record)
    render_error(:unprocessable_content, record.errors.full_messages.to_sentence.presence || "Invalid",
                 details: record.errors.to_hash(true), code: "invalid")
  end

  def render_forbidden(exception)
    message = current_user&.convoy_admin? && exception.query.to_s != "show?" ?
      "View only. Convoy Admin cannot change company data" : "You do not have access to this"
    render_error(:forbidden, message)
  end

  def render_internal_error(exception)
    Rails.error.report(exception, handled: true)
    render_error(:internal_server_error, "Something went wrong")
  end
end
