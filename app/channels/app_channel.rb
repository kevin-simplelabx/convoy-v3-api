# Convoy App: the signed-in person's own signals (Realtime): alerts_changed (fetch the inbox / badge again). Subscribe with
# { channel: "AppChannel" }.
class AppChannel < ApplicationCable::Channel
  def subscribed
    return reject unless app_account&.profile_complete?

    stream_from Realtime.app_stream(app_account.id)
  end
end
