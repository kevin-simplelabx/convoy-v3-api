# Notices into the Convoy App inboxes, once each, when the notice is in force (a scheduled one when it starts): run by
# AppAlertsJob inside each company. A School Bus notice to parents reaches every adult of the Families with a linked child at
# the school (or on the routes picked); a shuttle route notice to riders reaches the staff riders of that client whose Alert
# Settings for the route are on with Notices ticked and a ticked timing covered (not while Pause Alerts is set or the work
# email is overdue). A banner notice stays on Home until it ends (or is ended early). The notice is then marked app_sent_at.
module ConvoyApp
  module Alerts
    class Notices < ApplicationService
      def initialize(now: Time.current)
        @now = now
      end

      def call
        notices = Notice.active_at(@now).where(app_sent_at: nil).includes(:route_targets, :runs, :school, trip: :client).to_a
        return 0 if notices.empty?

        @company = ActsAsTenant.current_tenant
        written = notices.sum { it.for_school? ? school(it) : shuttle(it) }
        Notice.where(id: notices.map(&:id)).update_all(app_sent_at: @now, updated_at: @now)
        written
      end

      private

      def school(notice)
        return 0 unless notice.to_parents && notice.school_id

        pairs = FamilyRider.where.not(dependant_id: nil).where(school_id: notice.school_id)
        pairs = pairs.where(rid: SchoolRouteRider.where(school_route_id: notice.route_targets.map(&:school_route_id)).select(:rid)) unless notice.all_runs?
        kids = Alerts.kids(pairs.pluck(:school_id, :rid)).values
        Alerts.write(kids.flat_map do |kid|
          Alerts.rows_for(kid.account_ids, **base(notice), kind: "school_notice", title: "Notice from #{@company.name}", dependant_id: kid.dependant.id)
        end)
      end

      def shuttle(notice)
        trip = notice.trip
        return 0 unless notice.to_riders && trip&.kind == "corporate_shuttle"

        riders = ClientRider.live.where(client_id: trip.client_id).to_a
        accounts = AppAccount.where(id: riders.map(&:app_account_id)).includes(:identities).index_by(&:id)
        saved = ShuttleAlertSetting.includes(:setting_runs).where(app_account_id: accounts.keys, trip_id: trip.id).index_by(&:app_account_id)
        usuals = ShuttleUsual.includes(:trip_run).where(app_account_id: accounts.keys, client_id: trip.client_id).index_by(&:app_account_id)
        Alerts.write(riders.filter_map do |rider|
          account = accounts[rider.app_account_id]
          next unless account && live?(account, rider)

          setting = Shuttles::AlertSettings.effective(account, trip, Shuttles::UsualOf.new(usuals[account.id]), saved: saved[account.id])
          next unless setting.enabled && setting.notices && (notice.all_runs? || notice.runs.any? { setting.run_ids.include?(it.trip_run_id) })

          base(notice).merge(app_account_id: account.id, kind: "shuttle_notice", title: "Notice · #{trip.title}", trip_id: trip.id,
                             target: "shuttle_route", target_id: rider.id)
        end)
      end

      # The rider's work email is verified within 12 months and Pause Alerts is not set.
      def live?(account, rider) = Shuttles.email_live?(account, rider) && Shuttles::AlertSettings.paused_until(account).nil?

      def base(notice)
        { body: notice.message, company_id: @company.id, notice_id: notice.id, banner_until: notice.banner ? notice.ends_at : nil,
          dedupe_key: "notice:#{notice.id}" }
      end
    end
  end
end
