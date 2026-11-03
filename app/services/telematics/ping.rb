# One report from a device: where the bus is now, how fast, and the device's battery and signal (see Ingest, which takes
# a batch). Used by the seed and `live_map:simulate`. Returns the run the point went to, or nil.
module Telematics
  class Ping < ApplicationService
    def initialize(device:, at:, **report)
      @device = device
      @point = report.merge(at:)
    end

    def call = Ingest.call(device: @device, points: [ @point ])[:runs].first
  end
end
