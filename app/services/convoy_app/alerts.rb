# Convoy App › Alerts: the inbox rows (`app_notifications`) and who gets them. Writers (one class per source, in alerts/):
#   SchoolRuns  AppAlertsJob, every minute: morning trip started, bus 10 min away, running late (5 min, then every 5 more),
#               different bus (from 1 hour before the child's stop)
#   Notices     AppAlertsJob: a notice in force is copied once to the parents (school) / staff riders (shuttle route)
#   Attendance  Occurrences::MarkPassengers: a child boarded / alighted
#   Requests    BusRequest status changed (after commit, whoever changed it)
#   Bills       SchoolBills::Issue: a Family bill issued (Billing Contact)
#   Bookings    Bookings::Approve / Save / TripAction / CancelRequest: confirmed, changed, declined, cancelled, cancel declined
#   Invites     Links::Match (employer / bookings link), Households::InviteContacts (Family invite)
#   Shuttles::Alerts (Phase 6) writes the shuttle change alerts the same way.
# School Bus alerts go to every active adult of the Family; bills to the Billing Contact (decisions 2026-11-16). The account
# that did the thing itself (a parent withdrawing, a booker cancelling) is not told. Every row has a dedupe key, so a writer
# may run again without repeating an alert. Nothing is pushed (`pushed_at` stays empty).
module ConvoyApp
  module Alerts
    # A School Bus rider linked to a Family: the child, the Family's adults (account ids) and Billing Contacts.
    Kid = Data.define(:school_id, :rid, :dependant, :household_id, :account_ids)

    COLUMNS = { company_id: nil, trip_id: nil, occurrence_id: nil, occurrence_date: nil, dependant_id: nil, notice_id: nil, target: nil,
                target_id: nil, banner_until: nil }.freeze

    module_function

    # Inserts the rows (hashes with app_account_id, kind, title, body, dedupe_key and any of COLUMNS); returns how many were new.
    def write(rows)
      rows = rows.reject { it[:app_account_id].nil? }.uniq { [ it[:app_account_id], it[:dedupe_key] ] }
      return 0 if rows.empty?

      written = AppNotification.insert_all(rows.map { COLUMNS.merge(it) }, unique_by: %i[app_account_id dedupe_key], returning: %i[app_account_id])
      Realtime.alerts_changed(written.rows.flatten)
      written.length
    end

    # Runs a writer hooked into another action: an alert must never fail or roll back that action. In a savepoint (a failed
    # insert does not poison the caller's transaction); errors are reported, and raised only in tests.
    def safely
      ApplicationRecord.transaction(requires_new: true) { yield }
    rescue StandardError => e
      raise if Rails.env.test?

      Rails.error.report(e, handled: true, context: { source: "convoy_app_alerts" })
      0
    end

    # The same alert for several accounts.
    def rows_for(account_ids, **row) = account_ids.uniq.map { row.merge(app_account_id: it) }

    # The app account behind the current change (Convoy App calls are audited as the account), else nil.
    def actor = Audited.store[:audited_user].then { it.is_a?(AppAccount) ? it : nil }

    def without_actor(ids) = (a = actor) ? ids - [ a.id ] : ids

    # Riders linked to a Family in the current company, for [school_id, rid] pairs: { [school_id, rid] => Kid }.
    def kids(pairs)
      pairs = pairs.uniq
      return {} if pairs.empty?

      riders = FamilyRider.where.not(dependant_id: nil).where(school_id: pairs.map(&:first).uniq, rid: pairs.map(&:last).uniq)
                          .includes(:family).to_a.select { pairs.include?([ it.school_id, it.rid ]) }
      return {} if riders.empty?

      households = riders.filter_map { it.family.household_id }.uniq
      adults = adults_of(households)
      deps = Dependant.where(id: riders.map(&:dependant_id)).index_by(&:id)
      riders.filter_map do |fr|
        dep = deps[fr.dependant_id]
        next unless dep && fr.family.household_id

        [ [ fr.school_id, fr.rid ], Kid.new(school_id: fr.school_id, rid: fr.rid, dependant: dep, household_id: fr.family.household_id,
                                            account_ids: adults[fr.family.household_id] || []) ]
      end.to_h
    end

    # Active adults of Families (kept): { household_id => [account ids] }; billing: only Billing Contacts.
    def adults_of(household_ids, billing: false)
      return {} if household_ids.empty?

      scope = HouseholdMember.active.where(household_id: household_ids).where.not(app_account_id: nil).joins(:household).merge(Household.kept)
      scope = scope.where(billing_contact: true) if billing
      scope.pluck(:household_id, :app_account_id).group_by(&:first).transform_values { it.map(&:last) }
    end

    # Linked riders of the current company (School Bus): [[school_id, rid]].
    def linked_pairs = FamilyRider.where.not(dependant_id: nil).pluck(:school_id, :rid)

    # A notice ended early leaves Home at once.
    def notice_ended(notice, now: Time.current)
      AppNotification.where(notice_id: notice.id).where("banner_until > ?", now).update_all(banner_until: now, updated_at: now)
    end

    def hm(time) = time&.strftime("%H:%M")
  end
end
