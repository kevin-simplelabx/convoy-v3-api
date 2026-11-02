# SimpleDrive: MOM public holidays 2026-2027, an MOE school calendar and a general client calendar.
with_company("SD") do
  [ 2026, 2027 ].each { |y| PublicHoliday.import_preset!("SG", y) }

  moe = Calendar.find_or_create_by!(name: "MOE School Calendar") { |c| c.kind = :school }
  moe.apply_moe_preset!
  moe.days.find_or_create_by!(kind: :early, starts_on: "2026-11-20", ends_on: "2026-11-20") do |d|
    d.label = "Last day of term"
    d.usual_time = "13:30"
    d.new_time = "11:30"
  end
  moe.days.find_or_create_by!(kind: :ns, starts_on: "2026-11-06", ends_on: "2026-11-06") { |d| d.label = "PSLE Marking Day" }

  google = Calendar.find_or_create_by!(name: "Google Office Calendar") { |c| c.kind = :general }
  google.days.find_or_create_by!(kind: :off, starts_on: "2026-12-24", ends_on: "2026-12-24") { |d| d.label = "Office closed" }
  google.days.find_or_create_by!(kind: :shift, starts_on: "2026-12-31", ends_on: "2026-12-31") do |d|
    d.label = "New Year's Eve: shuttles one hour earlier"
    d.shift_minutes = -60
  end
  google.days.find_or_create_by!(kind: :work, starts_on: "2026-11-09", ends_on: "2026-11-09") { |d| d.label = "Deepavali Holiday: office open" }
end
