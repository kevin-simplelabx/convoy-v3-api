# Bookings: everyone in the company sees them; company users record and edit them (Convoy Admin views only).
class BookingPolicy < ApplicationPolicy
  def estimate? = true
end
