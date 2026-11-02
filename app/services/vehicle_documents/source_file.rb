# The file for a new vehicle document: an upload, or the file of a finished DocumentRead of the right kind.
module VehicleDocuments
  module SourceFile
    private

    def source_file(file, read, kind)
      return [ file, nil ] if file.present?
      raise ApplicationService::Error, "Add a file" if read.nil?
      raise ApplicationService::Error, "That read was for a #{read.kind.humanize.downcase}" if read.kind != kind

      [ read.file_copy, read.done? ? read.data : nil ]
    end

    # Fill the record's empty attributes from read values; returns the names filled.
    def fill_empty(record, values, fields)
      fields.filter_map do |f|
        next if values[f].blank? || record.public_send(f).present?

        record.public_send(:"#{f}=", values[f])
        f
      end
    end
  end
end
