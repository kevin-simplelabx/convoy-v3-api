# A rider (student) of a school's School Bus service: in an uploaded list (source csv) or added by hand (source manual,
# no list). Counts on a date between starts_on and ends_on (empty = open). rid is the school's student ID, kept the same
# across lists so changes match; cca_days are ISO weekdays (1 = Monday).
# == Schema Information
#
# Table name: school_riders
# Database name: primary
#
#  id               :bigint           not null, primary key
#  address          :string
#  am               :boolean          default(TRUE), not null
#  cca_days         :integer          default([]), not null, is an Array
#  ends_on          :date
#  first_name       :string
#  gender           :string
#  grade            :string
#  last_name        :string
#  lat              :decimal(10, 7)
#  lng              :decimal(10, 7)
#  name             :string           not null
#  name_order       :string           default("last"), not null
#  parent_contact   :string
#  parent_name      :string
#  pm               :boolean          default(TRUE), not null
#  postal           :string           not null
#  remarks          :text
#  rid              :string           not null
#  source           :string           default("csv"), not null
#  starts_on        :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :bigint           not null
#  created_by_id    :bigint
#  rider_dataset_id :bigint
#  school_id        :bigint           not null
#
# Indexes
#
#  index_school_riders_manual_rid                         (school_id,rid) UNIQUE WHERE (rider_dataset_id IS NULL)
#  index_school_riders_on_postal                          (postal)
#  index_school_riders_on_rider_dataset_id_and_rid        (rider_dataset_id,rid) UNIQUE WHERE (rider_dataset_id IS NOT NULL)
#  index_school_riders_on_school_id_and_rider_dataset_id  (school_id,rider_dataset_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (rider_dataset_id => rider_datasets.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id)
#
class SchoolRider < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  DAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze
  FILTERS = %w[all am pm cca unlocated].freeze

  belongs_to :school
  belongs_to :rider_dataset, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :source, { csv: "csv", manual: "manual" }, validate: true

  validates :rid, :name, presence: true
  validates :postal, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }
  validates :name_order, inclusion: { in: %w[first last] }
  validate :some_session
  validate :dates_in_order

  scope :on, ->(date) { where(starts_on: [ nil, ..date ]).where(ends_on: [ nil, date.. ]) }
  scope :search, lambda { |q|
    like = "%#{sanitize_sql_like(q.to_s.strip)}%"
    where("school_riders.name ILIKE :q OR school_riders.rid ILIKE :q OR school_riders.grade ILIKE :q OR school_riders.address ILIKE :q " \
          "OR school_riders.postal LIKE :q", q: like)
  }
  scope :filtered, lambda { |key|
    case key
    when "am" then where(am: true)
    when "pm" then where(pm: true)
    when "cca" then where.not(cca_days: [])
    when "unlocated" then where(lat: nil)
    else all
    end
  }

  # The riders of a school on a date: the list in use then, and the riders added by hand.
  def self.of_school_on(school, date)
    list = school.rider_datasets.in_use_on(date)
    where(school:).where(rider_dataset_id: [ nil, list&.id ].uniq).on(date)
  end

  # "Mon;Wed" (or "Mon, Wed", "monday") → [1, 3]; nil when a part is not a day.
  def self.parse_days(text)
    parts = text.to_s.split(/[;,\/\s]+/).compact_blank
    days = parts.map { |p| DAYS.index(p[0, 3].capitalize)&.+(1) }
    days.include?(nil) ? nil : days.uniq.sort
  end

  def cca_text = cca_days.map { DAYS[it - 1] }.join(";")
  def located? = lat.present?

  private

  def some_session
    errors.add(:base, "Pick at least one of AM, PM or CCA") unless am || pm || cca_days.any?
  end

  def dates_in_order
    errors.add(:ends_on, "is before the start date") if starts_on && ends_on && ends_on < starts_on
  end
end
