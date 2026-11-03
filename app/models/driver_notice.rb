# A notice from the office to drivers (Convoy Driver app › Notifications): ack = the office needs it read (route change,
# school closed) and records who acknowledged and when; view = an Open notice with a detail page (text, a picture and a
# link, e.g. a new depot map). Sent to every driver of the company or to the drivers picked (recipients).
# == Schema Information
#
# Table name: driver_notices
# Database name: primary
#
#  id            :bigint           not null, primary key
#  audience      :string           default("all"), not null
#  body          :text
#  ends_at       :datetime
#  from_name     :string
#  image         :string
#  image_caption :string
#  kind          :string           not null
#  link_label    :string
#  link_url      :string
#  starts_at     :datetime         not null
#  summary       :string
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#
# Indexes
#
#  index_driver_notices_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
class DriverNotice < ApplicationRecord
  include TenantScoped
  audited

  KINDS = %w[ack view].freeze

  belongs_to :created_by, class_name: "User", optional: true
  has_many :recipients, class_name: "DriverNoticeRecipient", dependent: :destroy, inverse_of: :notice

  mount_uploader :image, ImageUploader

  enum :kind, KINDS.index_with(&:itself), validate: true
  enum :audience, { all: "all", selected: "selected" }, prefix: :to, validate: true

  validates :title, :starts_at, presence: true
  validates :link_url, format: { with: %r{\Ahttps?://\S+\z}i, message: "must start with http:// or https://" }, allow_blank: true

  def live?(at = Time.current) = starts_at <= at && (ends_at.nil? || ends_at > at)
end
