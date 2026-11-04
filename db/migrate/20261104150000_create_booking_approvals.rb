# A Client Portal booking's way through the client's approval flow, kept as it was when the booking was sent (changing
# the flow later does not move it): the rule that matched, its steps and the people each step asked (why: the step's
# group, named, or the Admins when no one else was left), and every decision (approve / decline, with a note; carried:
# counted from an earlier step when the same person is on two steps).
class CreateBookingApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_approvals do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :booking, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.references :client_approval_rule, foreign_key: { on_delete: :nullify }
      t.string :flow_kind, null: false
      t.string :name, null: false
      t.string :status, null: false
      t.integer :current_step, null: false, default: 0
      t.string :same_person, null: false, default: "once"
      t.datetime :decided_at
      t.timestamps
      t.check_constraint "status IN ('wait', 'ok', 'no', 'none')", name: "booking_approvals_status"
      t.check_constraint "same_person IN ('once', 'other')", name: "booking_approvals_same_person"
    end
    add_index :booking_approvals, %i[company_id status]

    create_table :booking_approval_steps do |t|
      t.references :booking_approval, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.string :who, array: true, null: false, default: []
      t.string :need, null: false, default: "any"
      t.string :label, null: false
      t.boolean :fallback, null: false, default: false
      t.timestamps
    end
    add_index :booking_approval_steps, %i[booking_approval_id position], unique: true

    create_table :booking_approval_step_people do |t|
      t.references :booking_approval_step, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_user, null: false, foreign_key: true
      t.string :reason, null: false
      t.check_constraint "reason IN ('group', 'named', 'fallback')", name: "booking_approval_step_people_reason"
    end
    add_index :booking_approval_step_people, %i[booking_approval_step_id client_user_id], unique: true, name: "index_booking_approval_step_people_unique"

    create_table :booking_approval_acts do |t|
      t.references :booking_approval, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :booking_approval_step, null: false, foreign_key: { on_delete: :cascade }
      t.references :client_user, null: false, foreign_key: true
      t.string :act, null: false
      t.text :note
      t.integer :carried_from
      t.timestamps
      t.check_constraint "act IN ('approve', 'decline')", name: "booking_approval_acts_act"
    end
    add_index :booking_approval_acts, %i[booking_approval_id created_at]
  end
end
