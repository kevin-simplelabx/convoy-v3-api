# Stop Assignment tools. Select Riders: link riders (or every rider of a postal code) to a PUDO point by hand, as an
# alternative. Select Links › Remove: a hand link is deleted; a link that comes from the catchment is cut off for that
# rider (disconnected).
module SchoolStops
  module Links
    module_function

    def link(school, point, rids: [], postals: [], user: nil)
      raise ApplicationService::Error, "Pick riders or postal codes" if rids.empty? && postals.empty?

      RiderPointLink.transaction do
        targets = rids.map { { rid: it } } + postals.map { { postal: it } }
        targets.each do |t|
          RiderPointLink.where(school:, stop_point: point, kind: "disconnected", **t).delete_all
          RiderPointLink.find_or_create_by!(school:, stop_point: point, kind: "alternative", **t) { it.created_by = user }
        end
      end
    end

    def remove(school, links, user: nil)
      RiderPointLink.transaction do
        links.each do |l|
          hand = RiderPointLink.where(school:, stop_point_id: l[:point_id], kind: "alternative", rid: l[:rid])
          next hand.delete_all if hand.exists?

          RiderPointLink.find_or_create_by!(school:, stop_point_id: l[:point_id], kind: "disconnected", rid: l[:rid]) { it.created_by = user }
        end
      end
    end
  end
end
