class CreateEdipiPatients < ActiveRecord::Migration
  def change
    create_table :edipi_patients do |t|
      t.string :id
      t.string :system

      t.timestamps
    end
  end
end
