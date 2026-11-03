# Bus requests that need someone, across the schools a user can open, most urgent first (Convoy OS reqAlerts): mid-year
# requests to acknowledge, answers due within 3 working days or overdue, changes of address / service and stops not
# confirmed yet, and riders to take off the list. Feeds the bell, the strip on Ops Control / School Live Ops and the
# 08:00 email.
module BusRequests
  class Alerts
    STATUSES = [ "Requested", "Under Review", "Accepted", "Withdrawn", "Stopping", "Stopped", "Declined" ].freeze
    WORDS = { "adr" => [ "Change of address", ->(r) { "Moves #{r.effective_on&.strftime('%a %d/%m')}. Not opened yet" } ],
              "stop" => [ "Stop service", ->(r) { "Last day #{r.last_on&.strftime('%a %d/%m')}. Not confirmed yet" } ],
              "svc" => [ "Change of service", ->(r) { "From #{r.effective_on&.strftime('%a %d/%m')}. Not confirmed yet" } ] }.freeze

    def initialize(schools, today: Date.current)
      @schools = schools
      @today = today
    end

    def call
      days = Days.new(@today)
      reqs = BusRequest.where(school: @schools, status: STATUSES, ended_at: nil)
                       .includes(:school_rider, :first_bill, school: { academic_years: %i[registration terms] }, academic_year: %i[registration terms])
      items = reqs.filter_map do |r|
        n = BusRequests.needs(r, BusRequests.mid_settings(year_of(r)), @today, days) or next
        item(r, n)
      end
      items.sort_by { [ it[:rank], it[:by].to_s ] }
    end

    def self.summary(items)
      count = ->(&blk) { items.count(&blk) }
      ack = count.() { it.dig(:deadline, :stage) == "ack" }
      ans = count.() { it.dig(:deadline, :stage) == "answer" }
      chg = count.() { %w[adr svc stop].include?(it[:kind]) && it[:deadline].nil? }
      ends = count.() { it[:kind] == "end" }
      over = count.() { it[:tone] == "over" }
      parts = [ ("#{ack} to acknowledge" if ack.positive?), ("#{ans} #{ans == 1 ? 'answer' : 'answers'} due" if ans.positive?),
                ("#{chg} #{chg == 1 ? 'change' : 'changes'} of address" if chg.positive?), ("#{ends} to take off the rider list" if ends.positive?),
                ("#{over} overdue" if over.positive?) ].compact
      { count: items.size, overdue: over, to_acknowledge: ack, answers_due: ans, changes: chg, to_end: ends, parts:,
        text: parts.join(" | ").presence || "Nothing needs attention" }
    end

    private

    def year_of(r)
      r.academic_year || (d = r.start_on || r.effective_on || r.submitted_at.to_date) && r.school.academic_years.find { it.starts_on <= d && d <= it.ends_on }
    end

    def item(r, n)
      base = { request_id: r.id, code: r.code, child_name: r.child_name, level: r.level, school: { id: r.school.id, name: r.school.name },
               tab: %w[adr svc stop].include?(r.kind) ? r.kind : "new", kind: n[:kind] == "mid" ? "new" : n[:kind], rank: n[:rank], by: n[:by],
               deadline: n[:clock] }
      if n[:kind] == "end"
        base.merge(tone: "soon", what: n[:end][:label], text: n[:end][:text])
      elsif n[:clock].nil?
        what, text = WORDS[n[:kind]]
        base.merge(tone: "ok", what:, text: text.(r))
      else
        what = r.kind == "svc" ? "Change of service" : r.renew ? "Renewal" : n[:clock][:stage] == "ack" ? "New bus request" : "Answer due"
        base.merge(tone: n[:clock][:tone], what:, text: BusRequests.deadline_text(n[:clock]))
      end
    end
  end
end
