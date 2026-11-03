# A guardian of a family (Parent, Mother, Father, Guardian, Grandparent, Relative, Helper, Other) with a phone and email;
# app_joined_* = when and how they joined the family in the Convoy App (signup / invite).
# == Schema Information
#
# Table name: family_guardians
# Database name: primary
#
#  id             :bigint           not null, primary key
#  app_joined_at  :timestamptz
#  app_joined_how :string
#  email          :string
#  first_name     :string
#  last_name      :string
#  name_order     :string           default("last"), not null
#  phone          :string
#  position       :integer          default(0), not null
#  relationship   :string           default("Parent"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  family_id      :bigint           not null
#
# Indexes
#
#  index_family_guardians_on_email      (email)
#  index_family_guardians_on_family_id  (family_id)
#  index_family_guardians_on_phone      (phone)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id) ON DELETE => cascade
#
class FamilyGuardian < ApplicationRecord
  audited associated_with: :family

  RELATIONSHIPS = %w[Parent Mother Father Guardian Grandparent Relative Helper Other].freeze

  belongs_to :family, inverse_of: :guardians

  validates :relationship, inclusion: { in: RELATIONSHIPS }
  validates :name_order, inclusion: { in: %w[first last] }
  validates :phone, format: { with: /\A\+?[\d\s-]{8,}\z/, message: "doesn't look like a phone number" }, allow_blank: true
  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, message: "doesn't look like an email" }, allow_blank: true
  validate { errors.add(:base, "Enter a first name or last name") if first_name.blank? && last_name.blank? }

  def name = [ first_name, last_name ].compact_blank.then { name_order == "first" ? it : it.reverse }.join(" ")
  def phone_tail = phone.to_s.gsub(/\D/, "")[-8..]
end
