# Remove an entry from a trip's assignment history: its runs fall back to what was in force before it.
module Assignments
  class Remove < ApplicationService
    def initialize(assignment)
      @assignment = assignment
    end

    def call
      trip = @assignment.trip
      from = @assignment.effective_from
      TripAssignment.transaction do
        @assignment.destroy!
        Occurrences::Sync.call(trips: [ trip ], from: [ from, Date.current ].max)
      end
    end
  end
end
