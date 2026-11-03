# Runs: everyone in the company sees them; any company user may act on them from the Scheduler (Convoy Admin views only).
class TripOccurrencePolicy < ApplicationPolicy
  def cancel? = write?
  def restore? = write?
  def end? = write?
  def issue? = write?
  def time? = write?
  def move? = write?
  def share? = write?
  def note? = write?
  def correct? = write?

  def permitted_attributes_for_correct
    [ :outcome, :vehicle_id, :vehicle_plate, :driver_id, :driver_name, :reason, { stops: %i[position arrived_at departed_at boarded alighted] } ]
  end
end
