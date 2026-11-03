# Save Labels: the AM, PM and CCA / ASA route naming of a school, all at once.
module Schools
  class SaveLabels < ApplicationService
    def initialize(school, labels)
      @school = school
      @labels = labels
    end

    def call
      SchoolRouteLabel.transaction do
        @school.labels.each do |label|
          given = @labels[label.session] or next
          label.update!(given.slice(:prefix, :start, :digits, :suffix))
        end
      end
      @school.route_labels.reload
      @school
    end
  end
end
