# School Bus › Bus Service Registration: Convoy OS defaults from the year's first school day (renewals 122 to 79 days
# before, everyone from 78 days before to 242 days after), what scheduling needs, and the screen's shape.
module SchoolRegistrations
  FIELDS = %i[renew_from renew_to general_from general_to service_starts_on confirm_hours ack_days plan_weeks levels sessions grad_on
              grad_message grad_link auto_renew renew_check_address renew_check_session renew_check_debt auto_near near_km
              near_needs_cover auto_siblings siblings_need_cover run_mode run_at seats_buffer waitlist_auto show_fare extra_terms asks].freeze
  MESSAGE_FIELDS = %i[key enabled email whatsapp app offset_days offset_hours subject body whatsapp_body scheduled].freeze
  READY = { "calendar" => "Terms & Semesters", "sessions" => "Bus Sessions", "fares" => "Bus Fares", "policy" => "Payment & Refund Policy" }.freeze

  module_function

  def first_day(year) = year.terms.filter_map(&:starts_on).min || year.starts_on

  def build(year)
    start = first_day(year)
    year.build_registration(school: year.school, renew_from: start - 122, renew_to: start - 79, general_from: start - 78, general_to: start + 242,
                            service_starts_on: start, grad_message: SchoolRegistration::GRAD_MESSAGE)
  end

  # Terms & Semesters, Bus Sessions and Bus Fares locked and a Payment & Refund Policy in use.
  def ready(year, today = Date.current)
    locks = year.setup_locks.map(&:section)
    { "calendar" => locks.include?("calendar") && year.terms.any?, "sessions" => locks.include?("sessions"),
      "fares" => locks.include?("fares"), "policy" => year.school.policy_versions.any? { it.effective_on <= today } }
  end

  def messages(reg)
    saved = reg.messages.index_by(&:key)
    RegistrationMessage::PRESETS.map do |key, m|
      row = saved[key]
      { key:, name: m[:name], audience: m[:audience], anchor: m[:anchor], event: m[:event], adjustable: m[:adjustable], manual: m[:manual],
        enabled: row ? row.enabled : true, email: row ? row.email : true, whatsapp: row ? row.whatsapp : true, app: row ? row.app : true,
        offset_days: row&.offset_days || m[:offset_days], offset_hours: row&.offset_hours || m[:offset_hours], scheduled: row&.scheduled || false,
        subject: row&.subject || m[:subject], body: row&.body || m[:body], whatsapp_body: row&.whatsapp_body || m[:whatsapp],
        sends_on: send_date(reg, m, row), released_at: row&.released_at }
    end
  end

  # The date an anchored message goes out (09:00); nil when it follows an event or waits for Release Now.
  def send_date(reg, preset, row)
    return unless preset[:anchor]
    return if preset[:manual] && !row&.scheduled

    anchor = preset[:anchor] == "start" ? reg.service_starts_on : reg.public_send({ "eF" => :renew_from, "eT" => :renew_to, "gF" => :general_from }[preset[:anchor]])
    anchor && anchor + (row&.offset_days || preset[:offset_days])
  end

  def present(reg, today = Date.current)
    year = reg.academic_year
    policy = year.school.policy_versions.select { it.effective_on <= today }.max_by { [ it.effective_on, it.version ] }
    ready = ready(year, today)
    reg.slice(*FIELDS - %i[run_at]).symbolize_keys.merge(
      id: reg.id, year: year.key, status: reg.status, state: reg.state(today), run_at: reg.run_at_hm, saved: reg.persisted?,
      saved_at: reg.persisted? ? reg.updated_at : nil, saved_by: reg.saved_by&.name,
      ready: READY.map { |id, label| { id:, label:, ok: ready[id] } },
      final_levels: year.school.levels.select(&:final).map(&:name), school_levels: year.school.levels.map(&:name),
      policy: policy && { version: policy.version, registration_fee: policy.registration_fee, deposit_amount: policy.deposit_amount, ack_text: policy.ack_text },
      messages: messages(reg)
    )
  end
end
