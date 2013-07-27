class CreateRxOrders < ActiveRecord::Migration
  def change
    create_table :rx_orders do |t|
      t.string :fhirorder
      t.string :status

      t.timestamps
    end
  end
end
