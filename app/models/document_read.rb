# == Schema Information
#
# Table name: document_reads
# Database name: primary
#
#  id            :bigint           not null, primary key
#  error         :text
#  file          :string
#  finished_at   :datetime
#  input_text    :text
#  input_tokens  :integer
#  kind          :string           not null
#  model         :string
#  output_tokens :integer
#  result        :jsonb
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  user_id       :bigint
#
# Indexes
#
#  index_document_reads_on_company_id                          (company_id)
#  index_document_reads_on_company_id_and_kind_and_created_at  (company_id,kind,created_at)
#  index_document_reads_on_user_id                             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
# A file or pasted text read by Claude in the background (DocumentReadJob). The front end polls it, fills its form
# from `result`, then saves the form with document_read_id so the same file is attached without uploading it again.
class DocumentRead < ApplicationRecord
  acts_as_tenant :company

  READERS = {
    "log_card" => "Ai::Readers::LogCard",
    "insurance" => "Ai::Readers::Insurance",
    "trip_message" => "Ai::Readers::TripMessage",
    "maintenance_invoice" => "Ai::Readers::MaintenanceInvoice",
    "route_list" => "Ai::Readers::RouteList",
    "fuel_receipt" => "Ai::Readers::FuelReceipt"
  }.freeze

  mount_uploader :file, DocumentUploader

  belongs_to :user, optional: true

  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true

  validates :kind, inclusion: { in: READERS.keys }
  validate :file_or_text

  after_create_commit { DocumentReadJob.perform_later(company_id, id) }

  def reader = READERS.fetch(kind).constantize

  # Run the read (called by the job). A reader error leaves the read failed with a message for the user.
  def perform!
    data, reply = reader.read(attachment: file.presence, text: input_text)
    update!(status: :done, result: data, model: reply.model, input_tokens: reply.input_tokens,
            output_tokens: reply.output_tokens, finished_at: Time.current, error: nil)
  rescue ApplicationService::Error => e
    update!(status: :failed, error: e.message, finished_at: Time.current)
  end

  # Result keys as symbols ({} until done).
  def data = (done? && result || {}).deep_symbolize_keys

  # A copy of the read file to mount on another record.
  def file_copy
    raise ApplicationService::Error, "This read has no file" if file.blank?

    File.open(file.path)
  end

  private

  def file_or_text
    errors.add(:base, "Add a file or a message") if file.blank? && input_text.blank?
  end
end
