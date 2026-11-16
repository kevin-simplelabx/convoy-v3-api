# Writes the Convoy App's shuttle change alerts into the riders' inboxes (every 5 minutes; see ConvoyApp::Shuttles::Alerts).
class ShuttleAlertsJob < ApplicationJob
  queue_as :default

  def perform = ConvoyApp::Shuttles::Alerts.call
end
