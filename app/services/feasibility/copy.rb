# Feasibility Studies › Copy: the study with its students, bus prices, fare tiers and scenarios as "<name> copy"; the
# scenarios' results are left behind (Run them again).
module Feasibility
  class Copy < ApplicationService
    def initialize(study, user:)
      @study = study
      @user = user
    end

    def call
      FeasibilityStudy.transaction do
        copy = @study.dup.tap { it.assign_attributes(name: "#{@study.name} copy", created_by: @user) }
        copy.save!
        %i[rows bus_prices fare_tiers].each { |list| @study.public_send(list).each { copy.public_send(list) << it.dup } }
        @study.scenarios.each { copy.scenarios << it.dup.tap { |s| s.assign_attributes(result: nil, stale: false, status: "idle", error: nil, ran_at: nil) } }
        copy
      end
    end
  end
end
