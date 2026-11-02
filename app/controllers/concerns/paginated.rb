# Lists: ransack filter (params[:q]) + pagy page, rendered as { data: [...], meta: { page, limit, count, pages } }.
module Paginated
  extend ActiveSupport::Concern
  include Pagy::Backend

  private

  def render_page(scope, blueprint, meta: {}, **options)
    pagy, records = pagy(scope)
    render json: {
      data: blueprint.render_as_hash(present(records), **options),
      meta: { page: pagy.page, limit: pagy.limit, count: pagy.count, pages: pagy.pages }.merge(meta)
    }
  end

  # Small lists (types, teams, a client's sites): every row, no paging.
  def render_list(scope, blueprint, meta: {}, **options)
    render json: { data: blueprint.render_as_hash(present(scope), **options), meta: }
  end

  def ransack_params
    params.fetch(:q, {}).permit!.to_h
  end
end
