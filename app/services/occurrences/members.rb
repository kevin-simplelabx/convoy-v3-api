# The runs that move with one: its Runs That Move Together group on the same date (only itself when not grouped).
module Occurrences
  module Members
    module_function

    # [[trip_run_id, slot_no], ...] of the group the run slot is in.
    def slots(occ)
      return [ [ nil, 1 ] ] if occ.school_route_id

      gid = occ.trip_run&.slots&.find { |s| s.slot_no == occ.slot_no }&.trip_run_group_id
      return [ [ occ.trip_run_id, occ.slot_no ] ] if gid.nil?

      TripRunSlot.where(trip_run_group_id: gid).pluck(:trip_run_id, :slot_no)
    end

    # The member runs on the occurrence's date.
    def on_date(occ)
      slots(occ).filter_map do |run_id, slot|
        next occ if run_id == occ.trip_run_id && slot == occ.slot_no

        TripOccurrence.find_by(trip_id: occ.trip_id, date: occ.date, trip_run_id: run_id, slot_no: slot, part: 1)
      end
    end
  end
end
