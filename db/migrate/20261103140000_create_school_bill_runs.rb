# Each time Convoy drafts a school's bills for a billing period (by the daily job on the draft day, or Draft Now / Draft
# Again): when and by whom, the due date and label, and what it left out (children skipped, riders with no family).
class CreateSchoolBillRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :school_bill_runs do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :period_index, null: false
      t.string :label
      t.date :due_on
      t.string :skipped, array: true, null: false, default: []
      t.integer :unlinked, null: false, default: 0
      t.boolean :auto, null: false, default: false
      t.timestamptz :drafted_at, null: false
      t.references :drafted_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_bill_runs, %i[school_id academic_year_id period_index], unique: true
  end
end
