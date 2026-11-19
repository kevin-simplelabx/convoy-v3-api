# Convoy App live screens: { channel: "TrackChannel", screen:, …the screen's REST params }. The server reads the screen
# as its REST endpoint does (ConvoyApp::Watch: same access rules, refused when the screen is not the person's) and streams
# run_changed for every run on it and position for the runs whose bus the screen shows. It reads the screen again every
# REFRESH (a new run, School Live's 10-minute window): runs that leave stop streaming; when the screen is gone (Track
# Buses after the last bus) it sends { type: "gone" }.
class TrackChannel < ApplicationCable::Channel
  REFRESH = 30.seconds

  periodically :refresh, every: REFRESH

  def subscribed
    return reject unless app_account&.profile_complete?

    watch = read
    return reject unless watch

    @streams = Set.new
    follow(watch)
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def read = ConvoyApp::Watch.call(account: app_account, screen: params[:screen], params: params.except(:channel, :screen))

  def refresh
    return unless @streams

    watch = read
    if watch.nil?
      stop_all_streams
      @streams = nil
      transmit({ type: "gone" })
    else
      follow(watch)
    end
  end

  def follow(watch)
    wanted = watch[:runs].map { Realtime.run_stream(it) }.to_set | watch[:positions].map { Realtime.position_stream(it) }.to_set
    (@streams - wanted).each { stop_stream_from(it) }
    (wanted - @streams).each { stream_from(it) }
    @streams = wanted
  end
end
