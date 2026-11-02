# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  avatar                 :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_seen_at           :datetime
#  mobile                 :string
#  name                   :string           not null
#  owner                  :boolean          default(FALSE), not null
#  permissions            :string           default([]), not null, is an Array
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("member"), not null
#  status                 :string           default("active"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  company_id             :bigint
#
# Indexes
#
#  index_users_on_company_id            (company_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_permissions           (permissions) USING gin
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
FactoryBot.define do
  factory :user do
    company
    name { Faker::Name.name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password1!" }
    role { :member }

    trait(:admin) { role { :admin } }
    trait(:owner) { role { :admin }; owner { true } }
    trait(:convoy_admin) { role { :convoy_admin }; company { nil } }
    trait(:suspended) { status { :suspended } }
  end
end
