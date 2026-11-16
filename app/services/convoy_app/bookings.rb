# Convoy App › Bookings: the booking accounts of a person and what each may see. Accounts (decision 2026-11-04):
#   Personal — one per active company that takes Personal bookings (`companies.accepts_personal_bookings`): bookings of
#     the person's Individual client there (made on the first booking, `clients.app_account_id`), paid in the app.
#   link — each accepted, not paused booking link (a client user of a school / company whose role may book): the
#     bookings that client user made (here or in the Client Portal), and the Pay Myself bookings made from it (they
#     belong to the person's Individual client at that company, `bookings.booked_via_client_user_id`).
# A person never sees another person's bookings: every list is one of these scopes, read inside the account's company
# and time zone (`within`). Account keys in the API: "personal-<company_id>", "link-<client_user_id>".
module ConvoyApp
  module Bookings
    TONES = { "pending" => "warning", "approved" => "info", "confirmed" => "success", "ongoing" => "warning", "changed" => "warning",
              "cxreq" => "warning", "completed" => "neutral", "cancelled" => "danger", "rejected" => "danger" }.freeze
    LABELS = { "pending" => "Pending", "approved" => "Approved", "confirmed" => "Confirmed", "ongoing" => "In Progress", "changed" => "Changed",
               "cxreq" => "Cancel Requested", "completed" => "Completed", "cancelled" => "Cancelled", "rejected" => "Rejected" }.freeze
    TABS = { "current" => %w[confirmed ongoing approved], "pending" => %w[pending changed cxreq], "past" => %w[completed cancelled rejected] }.freeze
    # Booked less than this many days before the first day: the company first checks it has buses (HTML "short notice").
    SHORT_NOTICE_DAYS = 3

    # kind personal | link; client: the link's client, or the Individual client (nil before the first Personal booking).
    Account = Data.define(:key, :kind, :company, :client_user, :client, :app_account) do
      def personal? = kind == "personal"
      def link? = kind == "link"
      def tc = company.decorate.display_name
      def org = personal? ? "Personal" : client.name

      def json
        { key:, kind:, org:, company: { id: company.id, name: tc, ops_phone: company.ops_phone },
          role: personal? ? "Personal" : client_user.role_label, client: (link? ? { id: client.id, name: client.name } : nil),
          terms: personal? ? "prepaid" : "credit" }
      end
    end

    module_function

    def within(account, &) = Parents.within(account.company, &)

    # Every booking account of the person: Personal ones first, then links by organisation.
    def accounts(app_account, today: Date.current)
      personal(app_account) + links(app_account, today)
    end

    def account!(app_account, key) = accounts(app_account).find { it.key == key.to_s } || raise(ActiveRecord::RecordNotFound)

    # The person's bookings in this account. Inside `within`.
    def visible(account)
      if account.personal?
        return ::Booking.none unless account.client

        ::Booking.where(client_id: account.client.id, booked_via_client_user_id: nil)
      else
        mine = ::Booking.where(client_id: account.client.id, created_by_client_user_id: account.client_user.id)
        mine.or(::Booking.where(booked_via_client_user_id: account.client_user.id, created_by_app_account_id: account.app_account.id))
      end
    end

    # The account a booking id belongs to and the booking (inside that account's company), else 404.
    def find!(app_account, id)
      accounts(app_account).each do |account|
        found = within(account) { visible(account).find_by(id:) }
        return [ account, found ] if found
      end
      raise ActiveRecord::RecordNotFound
    end

    # The person's Individual client at the account's company, made the first time. Inside `within`.
    def individual!(account)
      found = individual_of(account.app_account)
      return found if found

      person = account.app_account
      mobile = person.identities.find(&:mobile?)&.value
      email = person.identities.find { it.email? && it.personal? }&.value || person.identities.find(&:email?)&.value
      raise ApplicationService::Error, "Add a mobile or email to your account first" if mobile.nil? && email.nil?

      Client.transaction(requires_new: true) do
        Client.create!(kind: "individual", name: person.display_name, phone: mobile, email:, app_account_id: person.id, contact_name: person.display_name)
      end
    rescue ActiveRecord::RecordNotUnique
      individual_of(account.app_account) || raise
    end

    def individual_of(app_account) = Client.kept.individual.find_by(app_account_id: app_account.id)

    # Who books: the client user on a school / company account, else the person; their mobile.
    def booker(account)
      phone = account.app_account.identities.find(&:mobile?)&.display
      if account.link?
        { name: account.client_user.name, role: account.client_user.title.presence, phone:, email: account.client_user.email }
      else
        email = account.app_account.identities.find { it.email? && it.personal? } || account.app_account.identities.find(&:email?)
        { name: account.app_account.display_name, role: nil, phone:, email: email&.value }
      end
    end

    # How Personal bookings are paid (Finance Settings: card with a fee in %, PayNow). Inside `within`.
    def payment_options
      s = FinanceSetting.current
      [ (Payments::Option.new(key: "card", label: "Card", icon: Payments::ICONS["card"], fee_kind: s.booking_card_fee_pct.positive? ? "pct" : "none",
                              fee: s.booking_card_fee_pct) if s.booking_card_on),
        (Payments::Option.new(key: "paynow", label: "PayNow", icon: Payments::ICONS["paynow"], fee_kind: "none", fee: 0.to_d) if s.booking_paynow_on) ].compact
    end

    def short_notice?(first_day, today = Date.current) = first_day.present? && first_day - SHORT_NOTICE_DAYS < today

    def money(amount) = "S$#{format('%.2f', amount.to_d)}"

    def personal(app_account)
      companies = Company.active.where(accepts_personal_bookings: true).order(:name).to_a
      companies.map do |company|
        client = Parents.within(company) { individual_of(app_account) }
        Account.new(key: "personal-#{company.id}", kind: "personal", company:, client_user: nil, client:, app_account:)
      end
    end

    def links(app_account, today)
      identities = app_account.identities.select { it.email? && it.work? }.index_by(&:value)
      users = ActsAsTenant.without_tenant do
        ClientUser.kept.where(app_account_id: app_account.id, app_link_status: "accepted", role: ClientUserAccess::BOOK).to_a
      end
      users = users.select { (identity = identities[it.app_matched_email]) && !identity.links_paused?(today) }
      companies = Company.active.where(id: users.map(&:company_id).uniq).index_by(&:id)
      users.filter_map do |user|
        company = companies[user.company_id] or next
        client = Parents.within(company) { Client.kept.find_by(id: user.client_id) } or next
        Account.new(key: "link-#{user.id}", kind: "link", company:, client_user: user, client:, app_account:)
      end.sort_by { [ it.client.name.downcase, it.tc.downcase ] }
    end
  end
end
