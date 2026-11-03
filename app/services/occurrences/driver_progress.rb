# The driver starts or ends a run in the Convoy Driver app (Ops Control, Live Map). The driver app endpoint calls this
# when it comes; the simulator uses it now. A run can be started early; it ends once.
module Occurrences
  class DriverProgress < ApplicationService
    ACTIONS = %w[start end].freeze

    def initialize(occurrence, action, at: Time.current)
      @occ = occurrence
      @action = action.to_s
      @at = at
    end

    def call
      raise Error, "Unknown action" unless ACTIONS.include?(@action)
      raise Error, "This run is #{@occ.status}" if LiveMap::NOT_DRIVEN.include?(@occ.status)
      raise Error, "This run has ended" if @occ.ended_at

      if @action == "start"
        @occ.update!(started_at: @at) unless @occ.started_at
      else
        @occ.update!(started_at: @occ.started_at || @at, ended_at: @at)
      end
      @occ
    end
  end
end
