# Models whose change moves trips' runs (public holidays, calendar days, calendars, company settings) re-sync the
# trips concerned in the background after commit (OccurrenceSyncJob). Each model says which trips and dates.
module SyncsOccurrences
  extend ActiveSupport::Concern

  private

  def resync_occurrences(trips, from: Date.current, to: nil, routes: [])
    ids = trips.pluck(:id)
    return if ids.empty? && routes.empty?

    from = [ from, Date.current ].max
    OccurrenceSyncJob.perform_later(company_id_for_sync, ids, from.iso8601, to&.iso8601, routes)
  end

  def company_id_for_sync = respond_to?(:company_id) ? company_id : id
end
