# Driver app: the signed-in driver's own signals (Realtime): runs_changed (fetch the runs list / the open run again) and
# notifications_changed (fetch the bell again). Subscribe with { channel: "DriverChannel" }.
class DriverChannel < ApplicationCable::Channel
  def subscribed
    return reject unless driver_account_id

    stream_from Realtime.driver_stream(driver_account_id)
  end
end
