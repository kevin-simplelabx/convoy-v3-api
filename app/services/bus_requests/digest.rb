# The 08:00 email to School Bus admins (owner, Admins, anyone with the Schools permission who opens those schools) on days
# with requests waiting; nothing on quiet days. Recorded (notification_emails) until email sending exists.
module BusRequests
  class Digest
    SUBJECT = "Bus requests waiting".freeze

    def initialize(company, today: Date.current)
      @company = company
      @today = today
    end

    # { to: [users], subject:, groups: [{ school:, rows: [{ who:, text:, tone: }] }], items: }
    def preview
      items = Alerts.new(School.where(company: @company), today: @today).call
      sids = items.map { it.dig(:school, :id) }.uniq
      users = User.where(company: @company, status: "active", discarded_at: nil).includes(:user_schools).select do |u|
        (u.owner? || u.admin? || u.permissions.include?("schools")) && (u.every_school? || u.user_schools.any? { sids.include?(it.school_id) })
      end
      summary = Alerts.summary(items)
      groups = items.group_by { it[:school] }.map do |school, rows|
        { school: school[:name], rows: rows.map { { who: [ it[:child_name], it[:level], it[:what] ].compact.join(", "), text: it[:text], tone: it[:tone] } } }
      end
      { to: users, subject: "#{SUBJECT}: #{summary[:parts].join(', ').presence || 'none'}", groups:, items: }
    end

    # Records today's email for each recipient, once a day.
    def call
      p = preview
      return 0 if p[:items].empty?

      body = p[:groups].map { |g| ([ g[:school] ] + g[:rows].map { "- #{it[:who]}: #{it[:text]}" }).join("\n") }.join("\n\n")
      sent = NotificationEmail.where(company: @company, created_at: @today.all_day).where("subject LIKE ?", "#{SUBJECT}:%").pluck(:user_id).to_set
      fresh = p[:to].reject { sent.include?(it.id) }
      fresh.each { NotificationEmail.create!(company: @company, user: it, to: it.email, subject: p[:subject], body:) }
      fresh.size
    end
  end
end
