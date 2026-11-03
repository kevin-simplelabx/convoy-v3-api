# Checks the runs on the Ops Control board now and keeps the company's alerts in step: raises the new ones, clears those
# whose problem went away (the Alert Log keeps them), escalates action alerts nobody acknowledged in 3 minutes. Run by the
# board and by OpsControlSyncJob every minute, under an advisory lock per company. Returns the checks for the board.
module OpsControl
  class Sync < ApplicationService
    def initialize(now: Time.current)
      @now = now
      @company = ActsAsTenant.current_tenant
    end

    def call
      OpsAlert.transaction do
        OpsAlert.connection.execute("SELECT pg_advisory_xact_lock(#{LOCK}, #{@company.id})")
        open = OpsAlert.open.to_a
        checks = load_checks(open.map(&:occurrence_id))
        live = checks.flat_map { |c| c.hits.map { |h| [ [ c.occ.id, h.kind, h.severity ], [ c, h ] ] } }.to_h
        held = open.index_by { |a| [ a.occurrence_id, a.kind, a.severity ] }
        raise_new(live.except(*held.keys))
        clear(held.except(*live.keys).values)
        escalate
        checks
      end
    end

    private

    def load_checks(alerted_ids)
      runs = OpsControl.runs(@now).or(TripOccurrence.where(id: alerted_ids, date: (@now.to_date - 2)..@now.to_date))
                       .includes(*INCLUDES).to_a
      sessions = Sessions.new(runs, @now)
      runs.map { |o| Check.new(o, now: @now, session: sessions.current(o), last_seen: sessions.last_seen(o)) }
    end

    def raise_new(hits)
      rows = hits.map do |(_key, (check, hit))|
        { company_id: @company.id, occurrence_id: check.occ.id, occurrence_date: check.occ.date, kind: hit.kind, severity: hit.severity,
          message: hit.message, raised_at: @now, created_at: @now, updated_at: @now }
      end
      OpsAlert.insert_all!(rows) if rows.any?
    end

    def clear(alerts)
      OpsAlert.where(id: alerts.map(&:id)).update_all(cleared_at: @now, updated_at: @now) if alerts.any?
    end

    def escalate
      OpsAlert.open.unacknowledged.where(severity: 2, escalated_at: nil, raised_at: ..(@now - ESCALATE_AFTER.minutes))
              .update_all(escalated_at: @now, updated_at: @now)
    end
  end
end
