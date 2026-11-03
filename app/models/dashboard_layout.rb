# A user's Dashboard layout: pages [{ name, items: [{ widget, x, y, cols, rows }] }] (8-column grid, up to 6 pages).
# == Schema Information
#
# Table name: dashboard_layouts
# Database name: primary
#
#  id         :bigint           not null, primary key
#  pages      :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_dashboard_layouts_on_user_id_and_company_id  (user_id,company_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
class DashboardLayout < ApplicationRecord
  include TenantScoped

  belongs_to :user

  validate :pages_shape

  private

  def pages_shape
    list = Array(pages)
    return errors.add(:pages, "can be 1 to #{Dashboard::Catalogue::MAX_PAGES}") unless list.size.between?(1, Dashboard::Catalogue::MAX_PAGES)

    list.each_with_index do |p, i|
      errors.add(:pages, "Page #{i + 1} needs a name") if p["name"].to_s.strip.empty?
      Array(p["items"]).each do |it|
        unless Dashboard::Catalogue::WIDGETS.key?(it["widget"]) && it["x"].to_i >= 0 && it["cols"].to_i.between?(1, 8) &&
               it["x"].to_i + it["cols"].to_i <= 8 && it["rows"].to_i.between?(1, 6) && it["y"].to_i >= 0
          errors.add(:pages, "Page #{i + 1} has a widget out of the grid")
        end
      end
    end
  end
end
