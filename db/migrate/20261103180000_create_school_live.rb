# School Bus › Live Ops: days a child does not need the bus (Bus Not Required from the Convoy App) and each child's
# attendance on a School Bus run (from the driver / attendant app: boarded, alighted, not boarded, not boarding today).
class CreateSchoolLive < ActiveRecord::Migration[8.1]
  def change
    create_table :school_rider_absences do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string :rid, null: false
      t.date :date, null: false
      t.string :trip, null: false, default: "both"
      t.string :reason, null: false, default: "other"
      t.string :note
      t.string :reported_by
      t.timestamps
    end
    add_index :school_rider_absences, %i[school_id rid date], unique: true
    add_index :school_rider_absences, %i[school_id date]

    create_table :school_rider_boardings do |t|
      t.references :company, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.references :school_route, null: false, foreign_key: true
      t.string :rid, null: false
      t.string :state, null: false
      t.datetime :boarded_at
      t.string :board_method
      t.float :board_lat
      t.float :board_lng
      t.datetime :alighted_at
      t.string :alight_method
      t.float :alight_lat
      t.float :alight_lng
      t.string :marked_by
      t.timestamps
    end
    add_index :school_rider_boardings, %i[occurrence_id occurrence_date rid], unique: true
  end
end
