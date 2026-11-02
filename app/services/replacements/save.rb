# Save a replacement from the Replace form (trip drawer) or Driver Away / Vehicle Down (vehicle panel), re-sync the
# runs it touches (and those it touched before an edit), and record who was told. A new replacement on a run replaces
# the one it had.
module Replacements
  class Save < ApplicationService
    # occurrence: the run (scope run); notify: { audiences: [], channels: [] }
    def initialize(replacement:, attributes:, user:, occurrence: nil, notify: nil)
      @rep = replacement
      @attrs = attributes
      @user = user
      @occ = occurrence
      @notify = notify
    end

    def call
      Replacement.transaction do
        before = @rep.persisted? ? Affected.snapshot(@rep) : nil
        @rep.assign_attributes(@attrs)
        attach_run if @occ
        @rep.created_by ||= @user
        check_handover_time!
        Replacement.where(scope: "run", trip_id: @rep.trip_id, school_route_id: @rep.school_route_id, run_date: @rep.run_date,
                          trip_run_id: @rep.trip_run_id, slot_no: @rep.slot_no).where.not(id: @rep.id).destroy_all if @rep.for_run?
        @rep.save!
        Affected.resync(@rep, before:)
        record_notice
        @rep
      end
    end

    private

    # The run's own bus before any replacement is the original vehicle.
    def attach_run
      @rep.assign_attributes(scope: "run", trip_id: @occ.trip_id, school_route_id: @occ.school_route_id, run_date: @occ.date,
                             trip_run_id: @occ.trip_run_id, slot_no: @occ.slot_no, original_vehicle_id: @occ.original_vehicle_id || @occ.vehicle_id)
      raise Error, "This run has no bus to replace" if @rep.original_vehicle_id.nil?
    end

    def check_handover_time!
      return unless @rep.kind_hand? && @occ && @rep.handover_time

      start, finish = @occ.start_time, @occ.end_time
      t = @rep.handover_time < start - 60 ? @rep.handover_time + 1440 : @rep.handover_time
      return if t > start && t < finish

      c = @occ.company
      raise Error, "The handover time must be during the trip, #{c.format_time(start)} to #{c.format_time(finish)}"
    end

    def record_notice
      return if @notify.blank? || Array(@notify[:audiences]).empty?

      @rep.notifications.create!(audiences: Array(@notify[:audiences]), channels: Array(@notify[:channels]),
                                 message: Wording.new(@rep).message, sent_by: @user)
    end
  end
end
