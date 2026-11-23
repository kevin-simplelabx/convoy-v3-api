# The push token of the phone a Convoy Driver app sign-in is on (API-ISSUES #18). Goes with the sign-in (cascade).
class CreateDriverDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_devices do |t|
      t.references :driver_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :driver_jwt, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :platform, null: false
      t.string :push_token, null: false, index: { unique: true }
      t.timestamps
      t.check_constraint "platform IN ('ios', 'android')", name: "driver_devices_platform"
    end
  end
end
