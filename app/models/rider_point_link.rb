# A rider (rid) or every rider of a postal code linked by hand to a PUDO point at a school — kind "alternative" (may
# use it although outside the catchment) or "disconnected" (may not use it although inside). Stop Assignment tools.
# == Schema Information
#
# Table name: rider_point_links
# Database name: primary
#
#  id            :bigint           not null, primary key
#  kind          :string           not null
#  postal        :string
#  rid           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#  school_id     :bigint           not null
#  stop_point_id :bigint           not null
#
# Indexes
#
#  index_rider_point_links_on_school_id_and_kind_and_postal  (school_id,kind,postal)
#  index_rider_point_links_on_school_id_and_kind_and_rid     (school_id,kind,rid)
#  index_rider_point_links_on_stop_point_id                  (stop_point_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (stop_point_id => stop_points.id) ON DELETE => cascade
#
class RiderPointLink < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  KINDS = %w[alternative disconnected].freeze

  belongs_to :school
  belongs_to :stop_point
  belongs_to :created_by, class_name: "User", optional: true

  validates :kind, inclusion: { in: KINDS }
  validate { errors.add(:base, "Link a rider or a postal code") unless [ rid, postal ].compact_blank.size == 1 }
end
