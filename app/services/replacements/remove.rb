# Remove a replacement: its runs go back to their regular bus and driver.
module Replacements
  class Remove < ApplicationService
    def initialize(rep)
      @rep = rep
    end

    def call
      Replacement.transaction do
        before = Affected.snapshot(@rep)
        @rep.destroy!
        if before[:trip_ids].any? || before[:route_ids].any?
          Occurrences::Sync.call(trips: before[:trip_ids], routes: before[:route_ids], from: [ before[:from], Date.current ].max, to: before[:to])
        end
      end
    end
  end
end
