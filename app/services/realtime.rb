# What goes out on the WebSocket (Driver app, Convoy App; .api-documents/integration.md § WebSocket). Small "changed"
# signals the app answers by fetching the REST endpoint again, and bus positions in full. Everything is sent once the
# surrounding transaction commits (nothing on a rollback); a pub/sub failure is reported, never raised into the write.
#   driver:<driver_account_id>   runs_changed { run_ids, dates }, notifications_changed       DriverChannel
#   app:<app_account_id>         alerts_changed                                              AppChannel
#   run:<occurrence_id>          run_changed { run_id }                                      TrackChannel
#   run:<occurrence_id>:position position { run_id, lat, lng, heading, speed_kmh, recorded_at } TrackChannel (screens that show it)
module Realtime
  module_function

  def driver_stream(account_id) = "driver:#{account_id}"
  def app_stream(account_id) = "app:#{account_id}"
  def run_stream(run_id) = "run:#{run_id}"
  def position_stream(run_id) = "run:#{run_id}:position"

  # Runs whose data changed (office edit, Sync, completion, driving actions): watchers of each run get run_changed, and each
  # driver on them (pass a row per driver before and after a change) gets runs_changed with their run ids and dates.
  #   runs: TripOccurrences or { id:, date:, driver_id:, operator_driver_id: } (without the driver keys: read from the run)
  def runs_changed(runs)
    rows = Array(runs).map { run_row(it) }.uniq
    return if rows.empty?

    after_commit do
      rows = with_drivers(rows)
      rows.map { it[:id] }.uniq.each { broadcast(run_stream(it), type: "run_changed", run_id: it) }
      accounts = driver_accounts(rows)
      rows.group_by { |r| accounts[[ :driver, r[:driver_id] ]] }.merge(rows.group_by { |r| accounts[[ :operator_driver, r[:operator_driver_id] ]] }) { |_, a, b| a + b }
          .except(nil).each do |account_id, list|
        broadcast(driver_stream(account_id), type: "runs_changed", run_ids: list.map { it[:id] }.uniq, dates: list.map { it[:date].to_s }.uniq.sort)
      end
    end
  end

  # New bell lines for these memberships ({ driver_id: } / { operator_driver_id: }).
  def notifications_changed(members)
    rows = Array(members).map { { driver_id: it[:driver_id], operator_driver_id: it[:operator_driver_id] } }.uniq
    return if rows.empty?

    after_commit do
      driver_accounts(rows).values.uniq.each { broadcast(driver_stream(it), type: "notifications_changed") }
    end
  end

  # New Convoy App alerts for these accounts.
  def alerts_changed(app_account_ids)
    ids = Array(app_account_ids).compact.uniq
    return if ids.empty?

    after_commit { ids.each { broadcast(app_stream(it), type: "alerts_changed") } }
  end

  # The newest point of each run in a GPS batch: { run => { at:, lat:, lng:, heading:, speed_kmh: } }.
  def positions(points_by_run)
    return if points_by_run.empty?

    after_commit do
      points_by_run.each do |run, p|
        broadcast(position_stream(run.id), type: "position", run_id: run.id, lat: p[:lat].to_f, lng: p[:lng].to_f, heading: p[:heading],
                                           speed_kmh: p[:speed_kmh]&.round, recorded_at: p[:at].iso8601)
      end
    end
  end

  # Closes the sockets of a sign-in that ended (sign out, another phone, account deleted).
  # (RemoteConnections needs every identifier of ApplicationCable::Connection, the other one nil.)
  def disconnect(jwt)
    ids = jwt.is_a?(DriverJwt) ? { driver_jwt: jwt, app_jwt: nil } : { driver_jwt: nil, app_jwt: jwt }
    after_commit { safely { ActionCable.server.remote_connections.where(ids).disconnect(reconnect: false) } }
  end

  def broadcast(stream, payload) = safely { ActionCable.server.broadcast(stream, payload) }

  def after_commit(&) = ActiveRecord.after_all_transactions_commit(&)

  # Errors are reported, and raised only in tests (as ConvoyApp::Alerts.safely).
  def safely
    yield
  rescue StandardError => e
    raise if Rails.env.test?

    Rails.error.report(e, handled: true, context: { realtime: true })
  end

  def run_row(run)
    h = run.respond_to?(:attributes) ? run.attributes.symbolize_keys : run.to_h
    h.slice(:id, :date, :driver_id, :operator_driver_id)
  end

  def with_drivers(rows)
    bare, full = rows.partition { !it.key?(:driver_id) }
    return rows if bare.empty?

    found = ActsAsTenant.without_tenant do
      TripOccurrence.where([ :id, :date ] => bare.map { [ it[:id], it[:date] ] }).pluck(:id, :date, :driver_id, :operator_driver_id)
    end
    full + found.map { |id, date, d, o| { id:, date:, driver_id: d, operator_driver_id: o } } + (bare.map { it[:id] } - found.map(&:first)).map { { id: it } }
  end

  # { [:driver, id] => driver_account_id, [:operator_driver, id] => driver_account_id } for the drivers with an app account.
  def driver_accounts(rows)
    own = rows.filter_map { it[:driver_id] }.uniq
    operator = rows.filter_map { it[:operator_driver_id] }.uniq
    ActsAsTenant.without_tenant do
      (own.empty? ? [] : Driver.where(id: own).where.not(driver_account_id: nil).pluck(:id, :driver_account_id).map { |id, a| [ [ :driver, id ], a ] }) +
        (operator.empty? ? [] : OperatorDriver.where(id: operator).where.not(driver_account_id: nil).pluck(:id, :driver_account_id).map { |id, a| [ [ :operator_driver, id ], a ] })
    end.to_h
  end
end
