# Students of a feasibility study at one postal code: how many, which session (both, AM, PM) and level.
# == Schema Information
#
# Table name: feasibility_rows
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  level                :string
#  postal               :string           not null
#  riders               :integer          default(1), not null
#  session              :string           default("both"), not null
#  feasibility_study_id :bigint           not null
#
# Indexes
#
#  index_feasibility_rows_on_feasibility_study_id  (feasibility_study_id)
#
# Foreign Keys
#
#  fk_rails_...  (feasibility_study_id => feasibility_studies.id) ON DELETE => cascade
#
class FeasibilityRow < ApplicationRecord
  belongs_to :feasibility_study, inverse_of: :rows

  validates :postal, format: { with: /\A\d{6}\z/ }
  validates :session, inclusion: { in: %w[both AM PM] }
end
