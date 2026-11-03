# Publish a Payment & Refund Policy version from a date (today or later), checked as Convoy OS does. A version that has
# not started yet is replaced (it keeps its number); otherwise the next number.
module Policies
  class Publish < ApplicationService
    def initialize(school, params, user:)
      @school = school
      @p = params
      @user = user
    end

    def call
      eff = date(@p[:effective_on]) or raise Error, "Pick the date this version applies from"
      raise Error, "The effective date cannot be in the past" if eff < Date.current

      check!
      SchoolPolicyVersion.transaction do
        scheduled = @school.policy_versions.where("effective_on > ?", Date.current).order(:effective_on).to_a
        number = scheduled.first&.version || (@school.policy_versions.maximum(:version).to_i + 1)
        scheduled.each(&:destroy!)
        v = @school.policy_versions.create!(@p.slice(*FIELDS).merge(version: number, effective_on: eff, published_by: @user))
        Array(@p[:reminders]).each.with_index(1) { |r, i| v.reminders.create!(r.slice(*REMINDER_FIELDS).merge(position: i)) }
        v
      end
    end

    private

    def n?(x) = x.present? && x.to_s.match?(/\A\d+(\.\d+)?\z/)

    def check!
      p = @p
      raise Error, "Enter how many days before the period fares are due" if p[:due_rule] == "before" && !n?(p[:due_days_before])
      raise Error, "Pick a due day from 1 to 28" if p[:due_rule] == "day" && !p[:due_day].to_i.between?(1, 28)
      raise Error, "Enter the grace period and overdue flag days" unless n?(p[:late_grace_days]) && n?(p[:late_flag_days])
      raise Error, "Enter the late fee" if p[:late_type] == "flat" && !n?(p[:late_flat])
      raise Error, "Enter the monthly interest" if p[:late_type] == "pct" && !n?(p[:late_pct])

      list = Array(p[:reminders])
      raise Error, "Keep at least one reminder" if list.empty?

      list.each do |r|
        channels = %i[email whatsapp app].select { r[it] }
        bad = channels.empty? || (r[:email] && (r[:email_subject].blank? || r[:email_body].blank?)) || (r[:whatsapp] && r[:whatsapp_body].blank?) ||
              (r[:app] && (r[:app_title].blank? || r[:app_body].blank?)) || (r[:timing] != "on" && !n?(r[:days]))
        raise Error, "#{when_text(r)}: pick a channel and fill in each message" if bad
      end
      raise Error, "Enter the notice period and refund timeline" unless n?(p[:withdrawal_notice]) && n?(p[:refund_within_days])
      raise Error, "Enter the deposit and registration fee" unless n?(p[:deposit_amount]) && n?(p[:registration_fee])
      unless n?(p[:address_notice_days]) && n?(p[:address_max_days]) && p[:address_max_days].to_i >= p[:address_notice_days].to_i
        raise Error, "Enter the change of address notice and how far ahead it can be booked (at least the notice)"
      end
      raise Error, "Enter the acknowledgement text" if p[:ack_required] && p[:ack_text].blank?
    end

    def when_text(r)
      return "On the due date" if r[:timing] == "on"

      "#{r[:days].to_i} day#{'s' unless r[:days].to_i == 1} #{r[:timing] == 'before' ? 'before' : 'after'} due"
    end

    def date(v)
      v.present? ? Date.iso8601(v.to_s) : nil
    rescue Date::Error
      raise Error, "The effective date must look like 2026-11-02"
    end
  end
end
