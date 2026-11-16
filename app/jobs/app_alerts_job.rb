# Writes the Convoy App's time-driven alerts into the inboxes (every minute; see ConvoyApp::Alerts::Sweep): notices in force
# and School Bus runs (trip started, bus 10 min away, running late, different bus).
class AppAlertsJob < ApplicationJob
  queue_as :default

  def perform = ConvoyApp::Alerts::Sweep.call
end
