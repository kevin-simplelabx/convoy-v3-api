# Notice templates for every company, and sample notices on the MBC Campus Shuttle for each Notices tab
# (scheduled next Monday, active today, ended yesterday).
Company.find_each do |company|
  ActsAsTenant.with_tenant(company) do
    NoticeTemplate::DEFAULTS.each { |t| NoticeTemplate.find_or_create_by!(name: t["name"]) { |n| n.message = t["message"] } }
  end
end

with_company("SD") do
  shuttle = Trip.kept.find_by!(label: "seed-mbc-shuttle")
  next if Notice.exists?(trip: shuttle)

  monday = Date.current.next_occurring(:monday)
  Notices::Save.call(notice: Notice.new, user: User.find_by!(email: "ops@simpledrive.sg"), start: "at", run_keys: %w[d1r0 d1r1],
                     attributes: { trip_id: shuttle.id, to_riders: true, banner: true, push: true,
                                   starts_at: Time.zone.local(monday.year, monday.month, monday.day, 7, 0),
                                   ends_at: Time.zone.local(monday.year, monday.month, monday.day, 9, 0),
                                   notice_template_id: NoticeTemplate.find_by!(name: "Route Change").id, message: "" })
end

with_company("SD") do
  shuttle = Trip.kept.find_by!(label: "seed-mbc-shuttle")
  ops = User.find_by!(email: "ops@simpledrive.sg")
  today = Date.current
  {
    "Heavy rain in the area today. The bus may arrive a few minutes late. Please wait under shelter." =>
      [ today.beginning_of_day, today.end_of_day, nil ],
    "The bus took a different route yesterday because of a road closure." =>
      [ today.yesterday.beginning_of_day + 7.hours, today.yesterday.beginning_of_day + 10.hours, ops ]
  }.each do |message, (starts_at, ends_at, ended_by)|
    next if Notice.exists?(trip: shuttle, message:)

    notice = Notices::Save.call(notice: Notice.new, user: ops, start: "at", run_keys: %w[all],
                                attributes: { trip_id: shuttle.id, to_riders: true, banner: true, starts_at:, ends_at:, message: })
    notice.update!(ended_at: ends_at - 1.hour, ended_by:) if ended_by
  end
end
