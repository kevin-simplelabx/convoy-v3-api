class StopLibrary < ApplicationRecord
  belongs_to :company

  def self.for_company(company)
    find_or_create_by!(company: company) do |sl|
      sl.lib      = []
      sl.counters = {}
    end
  end
end
