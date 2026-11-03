# Driver app sign-ins of the drivers of some runs, loaded at once: the current one (logged in) and when each driver was
# last in the app.
module OpsControl
  class Sessions
    RECENT = 30.days

    def initialize(runs, now)
      own = runs.filter_map(&:driver_id).uniq
      ops = runs.filter_map(&:operator_driver_id).uniq
      list = DriverAppSession.where(driver_id: own).or(DriverAppSession.where(operator_driver_id: ops))
                             .where(signed_in_at: (now - RECENT)..now).order(:signed_in_at).to_a
      @by = list.group_by { |s| s.driver_id ? [ :own, s.driver_id ] : [ :op, s.operator_driver_id ] }
    end

    def current(occ) = sessions(occ).reverse.find { |s| s.signed_out_at.nil? }
    def last_seen(occ) = sessions(occ).filter_map { |s| s.last_seen_at || s.signed_out_at || s.signed_in_at }.max

    private

    def sessions(occ)
      key = occ.driver_id ? [ :own, occ.driver_id ] : [ :op, occ.operator_driver_id ]
      @by[key] || []
    end
  end
end
