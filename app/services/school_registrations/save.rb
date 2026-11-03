# Save Draft / Save Changes / Schedule / Unschedule of a Bus Service Registration, with the Convoy OS checks. Scheduling
# needs the year's calendar, sessions and fares locked and a Payment & Refund Policy in use. Every save writes the 12
# messages; days are kept on the preset's side of the anchor and only adjustable timings change.
module SchoolRegistrations
  class Save < ApplicationService
    def initialize(year, params, user:, status: nil)
      @year = year
      @params = params
      @user = user
      @status = status
    end

    def call
      reg = @year.registration || SchoolRegistrations.build(@year)
      reg.assign_attributes(@params.slice(*FIELDS))
      reg.levels = Array(reg.levels).compact_blank & @year.school.levels.map(&:name) if @params.key?(:levels)
      reg.sessions = SchoolRegistration::SESSIONS.keys & Array(reg.sessions)
      reg.asks = SchoolRegistration::ASKS.keys & Array(reg.asks)
      reg.status = @status if @status
      check!(reg)
      ready! if reg.status == "scheduled" && (@status || reg.status_changed?)
      reg.saved_by = @user
      ApplicationRecord.transaction do
        reg.save!
        reg.touch if reg.saved_changes.blank?
        write_messages(reg) if @params.key?(:messages) || reg.messages.empty?
      end
      reg
    end

    private

    def check!(reg)
      error = if [ reg.renew_from, reg.renew_to, reg.general_from, reg.general_to, reg.service_starts_on ].any?(&:nil?) then "Enter every date in Schedule"
      elsif reg.renew_to < reg.renew_from then "The early window must end after it starts"
      elsif reg.general_from <= reg.renew_to then "The general window must open after the early window closes"
      elsif reg.general_to < reg.general_from then "The general window must end after it opens"
      elsif reg.sessions.empty? then "Pick at least one session"
      elsif !reg.confirm_hours.to_i.positive? then "Enter the hours parents have to confirm"
      elsif !reg.ack_days.to_i.positive? || !reg.plan_weeks.to_i.positive? then "Enter the mid-year reply times"
      elsif reg.auto_near && !reg.near_km.to_d.positive? then "Enter the distance for new applicants"
      elsif reg.run_mode == "daily" && reg.run_at.nil? then "Enter the time to run auto-accept"
      end
      raise Error, error if error
    end

    def ready!
      ready = SchoolRegistrations.ready(@year)
      missing = READY.reject { |id, _| ready[id] }.values
      raise Error.new("Finish #{missing.join(', ')} before scheduling", code: "not_ready", details: { missing: }) if missing.any?
    end

    def write_messages(reg)
      given = Array(@params[:messages]).index_by { it[:key].to_s }
      saved = reg.messages.index_by(&:key)
      RegistrationMessage::PRESETS.each do |key, preset|
        row = saved[key] || reg.messages.build(key:)
        p = given[key] || {}
        row.assign_attributes(p.slice(:enabled, :email, :whatsapp, :app, :subject, :body, :whatsapp_body).compact)
        row.subject ||= preset[:subject]
        row.body ||= preset[:body]
        row.whatsapp_body ||= preset[:whatsapp]
        row.scheduled = p[:scheduled] if preset[:manual] && !p[:scheduled].nil?
        row.offset_days = days(preset, p[:offset_days], row.offset_days)
        row.offset_hours = preset[:offset_hours] && (preset[:adjustable] && p[:offset_hours].present? ? p[:offset_hours].to_i.abs : row.offset_hours || preset[:offset_hours])
        row.save!
      end
    end

    def days(preset, given, current)
      return unless preset[:anchor]
      return current || preset[:offset_days] unless preset[:adjustable] && given.present?

      n = given.to_i.abs
      preset[:offset_days].negative? ? -n : n
    end
  end
end
