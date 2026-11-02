# == Schema Information
#
# Table name: notice_templates
# Database name: primary
#
#  id         :bigint           not null, primary key
#  message    :text             not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_notice_templates_on_company_id           (company_id)
#  index_notice_templates_on_company_id_and_name  (company_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A message template for notices (Delay, Breakdown, Route Change...). {min} and {time} are filled in by the sender.
class NoticeTemplate < ApplicationRecord
  include TenantScoped
  audited

  DEFAULTS = YAML.load_file(Rails.root.join("config/presets/notice_templates.yml")).freeze

  DEFAULT_NAME = "New Template"

  has_many :notices, dependent: :nullify

  # A template may be blank ("Blank": start from an empty message).
  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :company_id }
  validates :message, length: { maximum: Notice::MAX_MESSAGE }

  before_destroy :keep_one, prepend: true

  # "New Template", "New Template 2"... for Add Template.
  def self.next_default_name
    taken = where("name = :n OR name LIKE :like", n: DEFAULT_NAME, like: "#{DEFAULT_NAME} %").pluck(:name).to_set
    (1..).each do |i|
      name = i == 1 ? DEFAULT_NAME : "#{DEFAULT_NAME} #{i}"
      return name unless taken.include?(name)
    end
  end

  private

  def keep_one
    return if NoticeTemplate.where.not(id:).exists?

    errors.add(:base, "Keep at least one template")
    throw :abort
  end
end
