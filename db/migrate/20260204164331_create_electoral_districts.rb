class CreateElectoralDistricts < ActiveRecord::Migration[8.1]
  def change
    create_table :electoral_districts do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :district_type, null: false
      t.integer :seats_count
      t.string :ubigeo

      t.timestamps
    end

    add_index :electoral_districts, :code, unique: true
    add_index :electoral_districts, :name
    add_index :electoral_districts, :district_type
  end
end
