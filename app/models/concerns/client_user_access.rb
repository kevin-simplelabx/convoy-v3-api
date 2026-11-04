# What a client user may do in the Client Portal (logic/app-feed.js can, scope, covers, rolesToGive, userCan) and the
# Role Permissions table. Sites: an organisation-wide role covers every site; a site role covers only the sites picked
# for it (none left = nothing), unless the client has no sites at all; something with no site (a booking made in
# Convoy OS without one) is for organisation-wide roles only.
module ClientUserAccess
  extend ActiveSupport::Concern

  # What each role may do. The prototype also lists cancel and notices (super, adm, …): not built, so not here.
  CAN = {
    book: %w[super adm ssa sa member],
    see_all: %w[super adm fin ssa sa sfin],
    approve: %w[super adm fin ssa sa sfin],
    step_in: %w[super adm],
    users: %w[super adm ssa sa],
    rules: %w[super adm ssa sa],
    brand: %w[super adm],
    billing: %w[super adm fin sfin]
  }.freeze

  # Roles a manager may give.
  GIVES = { "super" => %w[super adm fin ssa sa sfin member], "adm" => %w[adm fin ssa sa sfin member],
            "ssa" => %w[ssa sa sfin member], "sa" => %w[sa sfin member] }.freeze

  ALL = %w[super adm fin ssa sa sfin member].freeze
  BOOK = %w[super adm ssa sa member].freeze
  MANAGE = %w[super adm ssa sa].freeze
  MONEY = %w[super adm fin sfin].freeze

  # The Role Permissions window (ROLE_FEAT of the prototype, word for word, rows not built yet included).
  FEATURES = [
    [ "Bookings", [
      [ "Make a booking", "Request trips priced from your rate card. When the booking meets an approval rule, it goes to the approvers before the transport company sees it.", BOOK ],
      [ "See bookings", "Organisation-wide roles see every booking. Site roles see the bookings for their sites. Members see the bookings they made.", ALL ],
      [ "Accept changes and ask to cancel", "Accept or reply to changes the transport company made, and ask to cancel a whole booking, a day or one trip.", BOOK ],
      [ "Approve bookings", "When an approval flow asks them: Site Admins of the booking's site, Finance, Admins or named people. Super Admins and Admins can decide any step.", %w[super adm fin ssa sa sfin] ]
    ] ],
    [ "Live Map and Shuttles", [
      [ "Live Map", "Buses on your own trips only, from when the driver heads out until the driver ends the trip. Schools see their school buses once the bus is assigned.", ALL ],
      [ "Shuttle routes and timetables", "Routes by site with their stops and times, read only. Shown only when the organisation has shuttles.", ALL ]
    ] ],
    [ "Money", [
      [ "See invoices and statements", "Invoices and statements from the transport company. Site Finance sees those of their sites.", MONEY ],
      [ "Pay invoices", "Pay by PayNow, bank transfer or card.", MONEY ],
      [ "Edit billing details", "Billing name, UEN, address, email and attention for the organisation and for sites billed as their own entity. Site Finance edits their sites only.", MONEY ]
    ] ],
    [ "Settings", [
      [ "See sites", "Sites with their address and who they are billed to. Site roles see only their sites.", ALL ],
      [ "Add and remove people", "Add people by work email and set their role and sites. Admins cannot remove or change a Super Admin. Site Super Admins and Site Admins manage people at their own sites; a Site Admin cannot remove a Site Super Admin.", MANAGE ],
      [ "Set approval flows", "The organisation's flow, and an own flow for any site. Site Super Admins and Site Admins set the flows of their own sites.", MANAGE ],
      [ "Logo and colour", "The organisation's logo and colour on the portal.", %w[super adm] ]
    ] ],
    [ "Notices", [
      [ "See notices to riders", "Notices in force or scheduled for your trips.", ALL ],
      [ "Send a notice to your riders", "An in-app banner and push to the riders of your own trips.", %w[super adm] ]
    ] ]
  ].freeze

  def can?(what) = CAN.fetch(what.to_sym).include?(role)

  # Every site of the client: an organisation-wide role, or a client with no sites.
  def all_sites? = wide? || !client_has_sites?

  def client_has_sites?
    return @client_has_sites if defined?(@client_has_sites)

    @client_has_sites = client.sites.exists?
  end

  # The site ids this person acts for, or nil for every site.
  def site_scope = all_sites? ? nil : picked_site_ids

  def covers?(site_id)
    return true if all_sites?

    site_id.present? && picked_site_ids.include?(site_id)
  end

  # Limits records with a site column to the sites this person covers (no site: organisation-wide roles only).
  def limit_to_sites(relation, column = :client_site_id)
    return relation if wide? || !client_has_sites?

    relation.where(column => picked_site_ids)
  end

  def roles_to_give = GIVES.fetch(role, [])

  # May this manager see, change or remove another client user of the same client. Organisation-wide managers see
  # everyone (an Admin cannot change or remove a Super Admin); site managers see people who share one of their sites and
  # change or remove only site users whose sites are all theirs and whose role they may give. Nobody removes themselves;
  # everyone sees themselves.
  def manages?(other, act)
    return act == :see && other.id == id unless can?(:users)
    return false if act == :remove && other.id == id
    return act == :see || !other.super? || super? if wide?
    return false if other.wide?

    shared, within = client_has_sites? ? site_overlap(other) : [ true, true ]
    act == :see ? shared || other.id == id : shared && within && roles_to_give.include?(other.role)
  end

  def picked_site_ids
    @picked_site_ids ||= user_sites.loaded? ? user_sites.map(&:client_site_id) : user_sites.pluck(:client_site_id)
  end

  def forget_sites!
    @picked_site_ids = nil
    user_sites.reset
  end

  private

  def site_overlap(other)
    theirs = other.picked_site_ids
    [ theirs.intersect?(picked_site_ids), theirs.any? && (theirs - picked_site_ids).empty? ]
  end
end
