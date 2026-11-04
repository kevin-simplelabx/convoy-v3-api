# Client Portal › Settings › Approval Flows: the organisation's flow (client_site_id null) and a site's own flow.
# Rules are checked from the top (position); the first whose conditions all match decides the steps; the Otherwise
# rule (one per flow, no conditions) takes the rest. A step goes to groups (Their Manager, Site Admins, Finance, Admins,
# named people), any one or everyone. Conditions on sites / bookers / teams are rows, so a removed site or team leaves
# the rule asking for it (sites_condition / booked_by_condition) instead of matching every booking. same_person: when one person is on two
# steps, once = their approval covers the later step too, other = the later step needs someone else.
class CreateClientApprovalFlows < ActiveRecord::Migration[8.1]
  def change
    create_table :client_approval_flows do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_site, foreign_key: { on_delete: :cascade }, index: false
      t.boolean :on, null: false, default: false
      t.timestamps
    end
    add_index :client_approval_flows, %i[client_id client_site_id], unique: true, nulls_not_distinct: true

    create_table :client_approval_rules do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :client_approval_flow, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false, default: 0
      t.boolean :otherwise, null: false, default: false
      t.string :name
      t.boolean :sites_condition, null: false, default: false
      t.boolean :booked_by_condition, null: false, default: false
      t.string :trip_kinds, array: true, null: false, default: []
      t.decimal :over_amount, precision: 12, scale: 2
      t.integer :lead_days
      t.string :same_person, null: false, default: "once"
      t.timestamps
      t.check_constraint "same_person IN ('once', 'other')", name: "client_approval_rules_same_person"
    end
    add_index :client_approval_rules, %i[client_approval_flow_id position]
    add_index :client_approval_rules, :client_approval_flow_id, unique: true, where: "otherwise", name: "index_client_approval_rules_one_otherwise"

    create_table :client_approval_rule_sites do |t|
      t.references :client_approval_rule, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_site, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :client_approval_rule_sites, %i[client_approval_rule_id client_site_id], unique: true, name: "index_client_approval_rule_sites_unique"

    create_table :client_approval_rule_bookers do |t|
      t.references :client_approval_rule, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_user, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :client_approval_rule_bookers, %i[client_approval_rule_id client_user_id], unique: true, name: "index_client_approval_rule_bookers_unique"

    create_table :client_approval_rule_teams do |t|
      t.references :client_approval_rule, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_team, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :client_approval_rule_teams, %i[client_approval_rule_id client_team_id], unique: true, name: "index_client_approval_rule_teams_unique"

    create_table :client_approval_steps do |t|
      t.references :client_approval_rule, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false, default: 0
      t.string :who, array: true, null: false, default: []
      t.string :need, null: false, default: "any"
      t.timestamps
      t.check_constraint "need IN ('any', 'all')", name: "client_approval_steps_need"
    end
    add_index :client_approval_steps, %i[client_approval_rule_id position]

    create_table :client_approval_step_people do |t|
      t.references :client_approval_step, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client_user, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :client_approval_step_people, %i[client_approval_step_id client_user_id], unique: true, name: "index_client_approval_step_people_unique"
  end
end
