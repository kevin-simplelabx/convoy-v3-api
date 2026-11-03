# School Bus › Stop Library photo requests: ask parents / drivers for photos of a PUDO point through the Convoy App,
# accept one as the point's photo (credited) or reject it, and the company's automatic requests for points with no photo.
module StopPhotos
  module_function

  def ask(point, audience:, user:, rider: nil, max: 6, auto: false)
    raise ApplicationService::Error, "#{point.pudo_code} already has an open photo request" if point.photo_requests.open.exists?
    raise ApplicationService::Error, "Pick the parent to ask" if audience == "parent" && rider.nil?

    point.photo_requests.create!(audience:, school_rider: rider, max_submissions: max.to_i.clamp(1, 12), auto:, created_by: user)
  end

  # The submission becomes the point's photo (or the edited image sent with it), credited to who took it; it keeps the
  # point's Street View link unless it has none. Any photo accepted before goes back to pending.
  def accept(sub, edited: nil, annotations: nil)
    point = sub.stop_photo_request.stop_point
    StopPhotoSubmission.transaction do
      sub.stop_photo_request.submissions.where(status: "accepted").where.not(id: sub.id).update_all(status: "pending") # rubocop:disable Rails/SkipsModelValidations
      sub.update!(status: "accepted", annotations: annotations || sub.annotations)
      point.photo = edited || File.open(sub.photo.path)
      point.photo_original = File.open(sub.photo.path)
      point.photo_annotations = annotations || sub.annotations
      point.photo_credit = "#{sub.submitted_by_name} (#{sub.role})"
      point.street_view_url = sub.street_view_url if point.street_view_url.blank?
      point.save!
    end
    point
  end

  def reject(sub) = sub.update!(status: "rejected")

  # Turn automatic requests from drivers / parents on or off: points of stops schools use, with no photo, get an open
  # request; turned off, automatic requests nobody answered go.
  def auto(company, driver:, parent:, user:)
    company.update!(stop_photo_auto_driver: driver, stop_photo_auto_parent: parent)
    audience = if driver && parent then "both" elsif driver then "driver" elsif parent then "parents" end
    changed = 0
    StopPoint.where(retired_at: nil, photo: nil, stop: Stop.kept.where(id: SchoolStop.select(:stop_id))).includes(photo_requests: :submissions).find_each do |p|
      open = p.photo_requests.find { it.status == "open" }
      if open
        next unless open.auto

        if audience.nil? then (open.live_count.zero? ? open.destroy! : next)
        elsif open.audience != audience then open.update!(audience:)
        else next
        end
      elsif audience then p.photo_requests.create!(audience:, auto: true, created_by: user)
      else next
      end
      changed += 1
    end
    changed
  end
end
