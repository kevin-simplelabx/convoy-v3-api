# Approve, reject and the client's steps on a booking trip: company users (Convoy Admin views only).
class BookingTripPolicy < ApplicationPolicy
  def approve? = write?
  def reject? = write?
  def acknowledge? = write?
  def client_approve? = write?
  def client_decline? = write?
end
