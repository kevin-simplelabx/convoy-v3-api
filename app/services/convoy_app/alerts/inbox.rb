# Convoy App › Alerts tab: the person's inbox, newest first, filter all | delays (running late) | notices, paged; grouped by
# the FE into Today / Earlier (`group`, Singapore time). `unread` is the tab badge.
module ConvoyApp
  module Alerts
    class Inbox < ApplicationService
      LIMIT = 30
      FILTERS = %w[all delays notices].freeze

      def initialize(account:, filter: nil, page: 1)
        @account = account
        @filter = FILTERS.include?(filter.to_s) ? filter.to_s : "all"
        @page = [ page.to_i, 1 ].max
      end

      def call
        scope = @account.notifications.filtered(@filter)
        count = scope.count
        rows = scope.includes(:company).newest.offset((@page - 1) * LIMIT).limit(LIMIT).to_a
        { data: rows.map { Inbox.json(it) },
          meta: { page: @page, limit: LIMIT, count:, pages: [ (count / LIMIT.to_f).ceil, 1 ].max, filter: @filter, unread: @account.notifications.unread.count } }
      end

      def self.json(n, today: Time.zone.today)
        { id: n.id, kind: n.kind, icon: n.icon, tone: n.tone, filter: n.filter_group, chip: n.chip, title: n.title, body: n.body, at: n.created_at,
          group: n.created_at.in_time_zone.to_date == today ? "today" : "earlier", read: n.read_at.present?, read_at: n.read_at,
          company: n.company&.name, dependant_id: n.dependant_id, target: n.target && { kind: n.target, id: n.target_id, trip_id: n.trip_id } }
      end
    end
  end
end
