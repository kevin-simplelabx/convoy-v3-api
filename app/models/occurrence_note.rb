# A note on a run in Trip History, kept with who wrote it and when.
# == Schema Information
#
# Table name: occurrence_notes
# Database name: primary
#
#  id              :bigint           not null, primary key
#  body            :text             not null
#  occurrence_date :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  author_id       :bigint
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#
# Indexes
#
#  index_occurrence_notes_on_author_id                          (author_id)
#  index_occurrence_notes_on_company_id                         (company_id)
#  index_occurrence_notes_on_occurrence_id_and_occurrence_date  (occurrence_id,occurrence_date)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#
class OccurrenceNote < ApplicationRecord
  include TenantScoped

  MAX_LENGTH = 1000

  belongs_to :author, class_name: "User", optional: true
  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :history_notes

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
end
