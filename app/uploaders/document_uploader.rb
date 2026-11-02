# Documents (trip attachments, route lists, invoices, log cards): PDF, images, spreadsheets, Word, CSV.
class DocumentUploader < ApplicationUploader
  def extension_allowlist
    %w[pdf jpg jpeg png webp heic xlsx xls csv doc docx txt]
  end
end
