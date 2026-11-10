# A version of a school's Payment & Refund Policy, in use from effective_on until a later version starts (Scheduled →
# In Use → Replaced): due dates, late charges, reminders, withdrawal and refunds, change of address, deposit and
# registration fee, acknowledgement. Publishing replaces a version that has not started yet (Policies::Publish).
# == Schema Information
#
# Table name: school_policy_versions
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  ack_reaccept        :boolean          default(TRUE), not null
#  ack_required        :boolean          default(TRUE), not null
#  ack_text            :text
#  address_max_days    :integer          default(90), not null
#  address_notice_days :integer          default(14), not null
#  address_start       :string           default("any"), not null
#  deposit_amount      :decimal(12, 2)   default(0.0), not null
#  deposit_return      :string           default("offset"), not null
#  due_day             :integer          default(1), not null
#  due_days_before     :integer          default(14), not null
#  due_rule            :string           default("before"), not null
#  effective_on        :date             not null
#  late_cap            :decimal(12, 2)
#  late_flag_days      :integer          default(30), not null
#  late_flat           :decimal(12, 2)
#  late_grace_days     :integer          default(7), not null
#  late_pct            :decimal(5, 2)
#  late_type           :string           default("flat"), not null
#  refund_basis        :string           default("days"), not null
#  refund_method       :string           default("credit"), not null
#  refund_within_days  :integer          default(30), not null
#  registration_fee    :decimal(12, 2)   default(0.0), not null
#  version             :integer          not null
#  withdrawal_fee      :decimal(12, 2)
#  withdrawal_notice   :integer          default(1), not null
#  withdrawal_unit     :string           default("months"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  published_by_id     :bigint
#  school_id           :bigint           not null
#
# Indexes
#
#  index_school_policy_versions_on_school_id_and_effective_on  (school_id,effective_on)
#  index_school_policy_versions_on_school_id_and_version       (school_id,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (published_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class SchoolPolicyVersion < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  DUE_RULES = %w[before day first].freeze
  LATE_TYPES = %w[none flat pct].freeze
  UNITS = %w[days weeks months].freeze
  REFUND_BASES = %w[days months term].freeze
  REFUND_METHODS = %w[credit bank parent].freeze
  ADDRESS_STARTS = %w[any mon first].freeze

  belongs_to :school
  belongs_to :published_by, class_name: "User", optional: true
  has_many :reminders, -> { order(:position) }, class_name: "PolicyReminder", dependent: :delete_all, inverse_of: :school_policy_version

  validates :due_rule, inclusion: { in: DUE_RULES }
  validates :late_type, inclusion: { in: LATE_TYPES }
  validates :withdrawal_unit, inclusion: { in: UNITS }
  validates :refund_basis, inclusion: { in: REFUND_BASES }
  validates :refund_method, inclusion: { in: REFUND_METHODS }
  validates :address_start, inclusion: { in: ADDRESS_STARTS }
  validates :deposit_return, inclusion: { in: %w[offset separate] }

  # The version in use on a date.
  def self.in_use_on(date = Date.current) = where(effective_on: ..date).order(effective_on: :desc, version: :desc).first

  # The version in use on a date among a school's versions (any Enumerable, so a preloaded list works): the latest that
  # has started, nil when none has (HTML polCur). Registration and strip step 5 need this one.
  def self.current_for(versions, date = Date.current) = versions.select { it.effective_on <= date }.max_by { [ it.effective_on, it.version ] }

  def state(versions, today = Date.current)
    return "scheduled" if effective_on > today

    self.class.current_for(versions, today) == self ? "in_use" : "replaced"
  end
end
