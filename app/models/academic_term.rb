# A semester or term of an academic year (position 1, 2, …) and its CCA / ASA period when it differs from the term.
# == Schema Information
#
# Table name: academic_terms
# Database name: primary
#
#  id               :bigint           not null, primary key
#  cca_ends_on      :date
#  cca_starts_on    :date
#  ends_on          :date
#  position         :integer          not null
#  starts_on        :date
#  academic_year_id :bigint           not null
#
# Indexes
#
#  index_academic_terms_on_academic_year_id_and_position  (academic_year_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#
class AcademicTerm < ApplicationRecord
  belongs_to :academic_year, inverse_of: :terms

  def covers?(date) = starts_on && ends_on && date.between?(starts_on, ends_on)
  def cca_covers?(date) = cca_starts_on && cca_ends_on && date.between?(cca_starts_on, cca_ends_on)
end
