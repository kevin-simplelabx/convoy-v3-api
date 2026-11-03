# Import a rider list: keeps the file, adds every readable row as a rider of the new list (rows with a problem are
# skipped and returned), then places the homes on the map in the background (SchoolRiders::LocateJob).
module SchoolRiders
  class Import < ApplicationService
    def initialize(school:, file:, effective_from:, user:)
      @school = school
      @file = file
      @effective_from = effective_from
      @user = user
    end

    def call
      raise Error, "Choose a CSV or XLSX file" unless @file.respond_to?(:path)
      raise Error, "Pick the Effective From date" if @effective_from.nil?

      result = FileReader.call(@file.path, File.extname(@file.original_filename))
      raise Error, result.errors.map { it[:message] }.join(". ") if result.rows.empty?

      dataset = RiderDataset.transaction do
        set = @school.rider_datasets.create!(effective_from: @effective_from, file: @file, file_name: @file.original_filename,
                                             uploaded_by: @user, riders_count: result.rows.size, status: "locating")
        now = Time.current
        SchoolRider.insert_all!(result.rows.map do |r|
          r.except(:line).merge(company_id: @school.company_id, school_id: @school.id, rider_dataset_id: set.id, source: "csv", created_at: now, updated_at: now)
        end)
        set
      end
      SchoolRidersLocateJob.perform_later(dataset.id)
      [ dataset, result.errors ]
    end
  end
end
