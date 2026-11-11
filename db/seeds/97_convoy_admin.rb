# Convoy Admin: Discover advertisers and placements (as the prototype samples them, with app counts), and Company
# Leads asked from the Convoy App. Platform data (no company).
admin = User.find_by!(email: "admin@convoy.sg")
sd = Company.find_by!(code: "SD")
today = Date.current

advertisers = [
  [ "SimpleDrive", "tc", true, 0, 5, "partners@simpledrive.sg" ], [ "Mandai Wildlife Group", "attr", false, 800, 8, "groupsales@mandai.com" ],
  [ "Kidz Sports Academy", "prog", false, 300, 12, "hello@kidzsports.sg" ], [ "Popular Bookstore", "brand", false, 500, 0, "marketing@popular.com.sg" ]
].to_h do |name, kind, premier, fee, pct, email|
  [ name, DiscoverAdvertiser.kept.find_or_create_by!(name:) { |a| a.assign_attributes(kind:, premier:, listing_fee: fee, commission_pct: pct, email:) } ]
end

[
  { title: "Mandai Zoo day trip for families", advertiser: "Mandai Wildlife Group", kind: "trip", kicker: "December Holidays",
    subtitle: "Coach from the East and zoo tickets, from S$58", price: 58, child_price: 42, seats: 200, event_on: today + 40,
    pickup_points: "Tampines Hub, Bedok Mall, Pasir Ris MRT", run_by_company: sd, sold_to_public: true, slot: "feat", audiences: %w[parents public],
    area: "east", starts_on: today - 20, ends_on: today + 38, status: "live", views: 18_420, taps: 1236, sold: 84 },
  { title: "Holiday sports camp, bus included", advertiser: "Kidz Sports Academy", kind: "prog", kicker: "Programme", background: "#212121",
    subtitle: "Pick-up from your usual school bus stop", price: 320, run_by_company: sd, audiences: %w[parents], school_level: "primary",
    starts_on: today + 7, ends_on: today + 45, status: "live" },
  { title: "15% off school books", advertiser: "Popular Bookstore", kind: "ad", kicker: "Back to School", cta: "Get the Code", promo_code: "CONVOY15",
    audiences: %w[parents staff], starts_on: today - 60, ends_on: today - 5, status: "live", views: 9200, taps: 410 },
  { title: "Live tracking for every shuttle", advertiser: nil, kind: "news", kicker: "From Convoy", cta: "See How", audiences: %w[staff bookers],
    starts_on: today, ends_on: today + 30, status: "draft" }
].each do |p|
  DiscoverPlacement.find_or_create_by!(title: p[:title]) do |x|
    x.assign_attributes(p.except(:advertiser).merge(advertiser: p[:advertiser] && advertisers[p[:advertiser]], created_by: admin))
    x.assign_attributes(listing_fee: x.advertiser.listing_fee, commission_pct: x.advertiser.commission_pct) if x.advertiser
  end
end

unless CompanyLead.exists?
  [ [ "acme.com.sg", "Acme Logistics", [ 2, 3, 5, 8, 13, 20, 31 ] ], [ "brightminds.edu.sg", "Bright Minds Preschool", [ 4, 9, 15 ] ],
    [ "harbourfront.sg", "HarbourFront Centre", [ 6 ] ] ].each do |dom, co, days|
    days.each_with_index do |d, i|
      CompanyLead.create!(domain: dom, company_name: i.zero? ? "#{co} Pte Ltd" : co, asked_at: d.days.ago,
                          contact: i == 1 ? "Facilities: Jason Lim, jason.lim@#{dom}" : nil, named_name: i == 2 ? "Wei Ling" : nil, named_via: i == 2 ? "Convoy app" : nil)
    end
  end
  CompanyLeadDomain.create!(domain: "brightminds.edu.sg", status: "demo", note: "Demo on Thursday with the centre manager", updated_by: admin)
end

# Add-ons: SimpleDrive has both; Island Coaches has Import Route List off and School Run on, Comfort Charter has both off (to test the off state).
sd.update!(school_run_enabled: true, route_list_import_enabled: true)
Company.find_by(code: "ICS")&.update!(school_run_enabled: true, route_list_import_enabled: false)
Company.find_by(code: "CCS")&.update!(school_run_enabled: false, route_list_import_enabled: false)
