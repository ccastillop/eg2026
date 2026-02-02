class CreateCandidates < ActiveRecord::Migration[8.1]
  def change
    create_table :candidates do |t|
      t.references :political_organization, null: false, foreign_key: true
      t.string :position_type, null: false
      t.integer :position_number
      t.string :document_type
      t.string :document_number, null: false
      t.string :first_name
      t.string :paternal_surname
      t.string :maternal_surname
      t.string :gender
      t.string :birth_date
      t.string :is_native
      t.string :status
      t.string :photo_guid
      t.string :photo_filename
      t.string :department
      t.string :province
      t.string :district
      t.string :electoral_file_code

      t.timestamps
    end

    add_index :candidates, :document_number
    add_index :candidates, :position_type
    add_index :candidates, :status
    add_index :candidates, :department
  end
end
