# Reads a DocumentRead with Claude inside its company and timezone ("today" in a trip message).
class DocumentReadJob < ApplicationJob
  queue_as :default

  def perform(company_id, document_read_id)
    company = Company.find(company_id)
    ActsAsTenant.with_tenant(company) do
      Time.use_zone(company.timezone) do
        read = DocumentRead.find(document_read_id)
        read.perform! if read.pending?
      end
    end
  end
end
