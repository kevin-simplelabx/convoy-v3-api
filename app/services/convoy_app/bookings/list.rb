# Convoy App › Bookings list of one account: tabs Current (confirmed, in progress, approved), Pending (pending, changed,
# cancel requested), Past (completed, cancelled, rejected), All. A booking with a trip still to run (not cancelled /
# declined, today or later) is "open" (few per person: read whole, status worked out, split Current / Pending, in
# progress first then by first day); the others are Past (newest first day first, paged in SQL). All = open then past.
# Inside `within`.
module ConvoyApp
  module Bookings
    class List < ApplicationService
      LIMIT = 20

      def initialize(account:, tab:, page: 1, now: Time.current)
        @account = account
        @tab = %w[current pending past all].include?(tab) ? tab : "current"
        @page = [ page.to_i, 1 ].max
        @now = now
        @today = now.to_date
      end

      def call
        from = (@page - 1) * LIMIT
        open = %w[past].include?(@tab) ? [] : open_rows
        open = open.select { it[:tab] == @tab } unless @tab == "all"
        data = open[from, LIMIT] || []
        count = open.size
        if %w[past all].include?(@tab)
          past = scope.where("NOT EXISTS (#{open_sql})")
          count += past.count
          need = LIMIT - data.size
          data += past_rows(past, [ from - open.size, 0 ].max, need) if need.positive?
        end
        { account: @account.json, tab: @tab, data:, meta: { page: @page, limit: LIMIT, count:, pages: [ (count / LIMIT.to_f).ceil, 1 ].max } }
      end

      private

      def open_sql
        BookingTrip.joins(:day).where("booking_trips.booking_id = bookings.id").where.not(status: %w[cancelled rejected])
                   .where(booking_days: { date: @today.. }).select(1).to_sql
      end

      def scope = Bookings.visible(@account)

      def first_day_sql = "(SELECT MIN(booking_days.date) FROM booking_days WHERE booking_days.booking_id = bookings.id)"

      def cards(bookings)
        runs = Runs.load(bookings, now: @now)
        bookings.map { Present.new(@account, it, runs, now: @now).card }
      end

      def open_rows
        list = cards(scope.where("EXISTS (#{open_sql})").includes(*Present::INCLUDES).to_a)
        list.sort_by { [ it[:status] == "ongoing" ? 0 : 1, it[:first_date] || @today, it[:id] ] }
      end

      def past_rows(past, offset, limit)
        cards(past.includes(*Present::INCLUDES).order(Arel.sql("#{first_day_sql} DESC"), id: :desc).offset(offset).limit(limit).to_a)
      end
    end
  end
end
