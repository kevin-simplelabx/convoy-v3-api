# Sends saved bell / inbox lines as push notifications (Push.later queues it after commit). source: "driver" | "app".
class PushJob < ApplicationJob
  queue_as :default

  SOURCES = { "driver" => "Push::DriverNotifications", "app" => "Push::AppAlerts" }.freeze

  def perform(source, ids)
    SOURCES.fetch(source).constantize.call(ids:)
  end
end
