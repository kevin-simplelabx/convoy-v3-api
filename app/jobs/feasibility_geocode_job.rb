# Looks up a feasibility study's student postal codes on OneMap in the background (Feasibility::Geocode); the study shows
# each row as found / not found / pending while it runs.
class FeasibilityGeocodeJob < ApplicationJob
  queue_as :default

  def perform(study_id)
    study = ActsAsTenant.without_tenant { FeasibilityStudy.find_by(id: study_id) } or return
    ActsAsTenant.with_tenant(study.company) { Feasibility::Geocode.call(study) }
  end
end
