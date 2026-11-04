# Route Plans › route drawer price card: the route's own Bus Attendant settings (empty = the school's default) and, for
# a route with no bus, who is paid for it (our own buses, or a transport operator).
class AddAttendantAndPayToToSchoolRoutes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :school_routes, :attendant_required, :boolean
    add_column :school_routes, :attendant_provided_by, :string
    add_column :school_routes, :attendant_price, :decimal, precision: 12, scale: 2
    add_column :school_routes, :pay_to, :string
    add_reference :school_routes, :pay_to_operator, index: { algorithm: :concurrently }
    add_foreign_key :school_routes, :operators, column: :pay_to_operator_id, validate: false
  end
end
