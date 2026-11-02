# Rate cards: anyone in the company may read them and ask for a quote (trip form); company users edit them on
# Trips > Rate Cards (Convoy Admin views only).
class RateCardPolicy < ApplicationPolicy
  def quote? = true
  def check? = true
  def make_default? = write?
  def archive? = write?
  def unarchive? = write?
end
