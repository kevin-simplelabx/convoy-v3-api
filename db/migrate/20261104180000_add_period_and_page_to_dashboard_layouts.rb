# Company Dashboard: the period picked (kept like the prototype, Last 7 Days until changed) and the page open last.
class AddPeriodAndPageToDashboardLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :dashboard_layouts, :period, :string, null: false, default: "d7"
    add_column :dashboard_layouts, :page, :integer, null: false, default: 0
  end
end
