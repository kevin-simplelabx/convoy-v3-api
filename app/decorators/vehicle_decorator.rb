class VehicleDecorator < ApplicationDecorator
  # Illustration used when the vehicle has no photo (assets/fleet/iso/sq/<key>.png on the front end).
  def default_picture
    s = seats.to_i
    if s.zero? || s <= 4 then "sedan-4"
    elsif s <= 7 then vip? ? "mpv-vip-6" : "mpv-6"
    elsif s <= 15 then "hiace-commuter-hr"
    elsif s <= 30 then "coaster"
    elsif s <= 44 then "coach-40"
    else "yutong-zk6117h"
    end
  end

  # Current policy in one line for the list: { insurer, ends_on, status expired | due_soon | valid | none }.
  # Always an object: no current policy gives { insurer: nil, ends_on: nil, status: "none" }.
  def insurance_summary
    p = current_insurance_policy
    return { insurer: nil, ends_on: nil, status: "none" } unless p

    { insurer: p.insurer, ends_on: p.ends_on, status: p.expiry_status }
  end

  def size_name = Vehicle::SIZE_NAMES[size]

  def photo_info = file_info(:photo, versions: [ :thumb ])

  # Driver today: { id, kind own|operator|external, name, phone }.
  def driver_today
    d = default_driver_on(Date.current)
    if d then { id: d.id, kind: d.is_a?(Driver) ? "own" : "operator", name: d.name, phone: d.phone }
    elsif driver_name.present? then { id: nil, kind: "external", name: driver_name, phone: driver_phone }
    end
  end

  # Default driver changes still to come on an own bus: [{ starts_on, start_time, driver: { id, name } | nil }].
  def upcoming_drivers
    return [] unless own?

    driver_schedules.select { |s| s.starts_on > Date.current }.sort_by(&:sort_key)
                    .map { |s| { starts_on: s.starts_on, start_time: s.start_time_hm, driver: s.driver && { id: s.driver.id, name: s.driver.name } } }
  end
end
