# Bus Attendants: which buses of a school need one — sizes the law requires (statutory), all sizes, or chosen sizes (the
# law's always included) — and who usually provides them (the operator or us). Prices come from Operator Pay.
# == Schema Information
#
# Table name: school_attendant_policies
# Database name: primary
#
#  id          :bigint           not null, primary key
#  needs       :string           default("statutory"), not null
#  provided_by :string           default("operator"), not null
#  sizes       :string           default([]), not null, is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  school_id   :bigint           not null
#
# Indexes
#
#  index_school_attendant_policies_on_school_id  (school_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolAttendantPolicy < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  NEEDS = %w[statutory all selected].freeze
  PROVIDERS = %w[operator us].freeze

  belongs_to :school

  validates :needs, inclusion: { in: NEEDS }
  validates :provided_by, inclusion: { in: PROVIDERS }
  validates :sizes, length: { minimum: 1, message: "pick at least one bus size" }, if: -> { needs == "selected" }
  validate { errors.add(:sizes, "has an unknown bus size") unless (sizes - SchoolBus::BUS_TYPES.keys).empty? }

  before_validation { self.sizes = (sizes | SchoolBus.statutory_sizes).sort if needs == "selected" }

  # Bus sizes that need an attendant.
  def needed_sizes
    case needs
    when "all" then SchoolBus::BUS_TYPES.keys
    when "selected" then sizes
    else SchoolBus.statutory_sizes
    end
  end
end
