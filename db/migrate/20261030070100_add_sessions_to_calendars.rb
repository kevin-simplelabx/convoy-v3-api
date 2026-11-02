class AddSessionsToCalendars < ActiveRecord::Migration[8.1]
  def change
    # Regular sessions of a school calendar (minutes): trips nearer the morning one move on Late Arrival,
    # the others on Early Dismissal.
    add_column :calendars, :morning_time, :integer, null: false, default: 450   # 07:30 usual arrival
    add_column :calendars, :afternoon_time, :integer, null: false, default: 810 # 13:30 usual dismissal
  end
end
