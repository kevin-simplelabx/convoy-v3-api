# School Bus routes on the Scheduler.
module SchoolRoutes
  # Routes of plans running from today on (Daily upkeep, seeds).
  def self.running_ids = SchoolRoute.joins(:plan).merge(SchoolPlan.running_between(Date.current, Occurrences::Sync.horizon)).pluck(:id)
end
