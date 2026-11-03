# The Convoy Driver app's bell: what changed for the driver (a trip given or taken away, moved, cancelled, a bus to take
# over) and notices from the office — Acknowledge ones (a route change the office needs read, with the time) and Open
# ones (a detail page with text, a picture and a link). Push is recorded (pushed_at) once a push service is set up.
class CreateDriverNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_notices do |t|
      t.references :company, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.string :summary
      t.text :body
      t.string :image
      t.string :image_caption
      t.string :link_url
      t.string :link_label
      t.string :from_name
      t.string :audience, null: false, default: "all"
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :driver_notice_recipients do |t|
      t.references :driver_notice, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :driver, foreign_key: { on_delete: :cascade }
      t.references :operator_driver, foreign_key: { on_delete: :cascade }
      t.datetime :read_at
      t.datetime :acknowledged_at
      t.timestamps
      t.check_constraint "num_nonnulls(driver_id, operator_driver_id) = 1", name: "driver_notice_recipients_one_driver"
    end
    add_index :driver_notice_recipients, %i[driver_notice_id driver_id operator_driver_id], unique: true, name: "index_driver_notice_recipients_unique"

    create_table :driver_notifications do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, foreign_key: { on_delete: :cascade }, index: false
      t.references :operator_driver, foreign_key: { on_delete: :cascade }, index: false
      t.string :kind, null: false
      t.string :title, null: false
      t.string :body
      t.bigint :occurrence_id
      t.date :occurrence_date
      t.references :vehicle, foreign_key: { on_delete: :nullify }, index: false
      t.references :driver_notice, foreign_key: { on_delete: :cascade }, index: false
      t.datetime :read_at
      t.datetime :pushed_at
      t.timestamps
      t.check_constraint "num_nonnulls(driver_id, operator_driver_id) = 1", name: "driver_notifications_one_driver"
    end
    add_index :driver_notifications, %i[driver_id created_at], where: "driver_id IS NOT NULL"
    add_index :driver_notifications, %i[operator_driver_id created_at], where: "operator_driver_id IS NOT NULL"
  end
end
