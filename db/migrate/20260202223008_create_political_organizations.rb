class CreatePoliticalOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :political_organizations do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :acronym
      t.string :organization_type
      t.string :status
      t.string :registration_date
      t.string :cancellation_date
      t.string :website
      t.text :address
      t.string :logo_url

      t.timestamps
    end

    add_index :political_organizations, :code, unique: true
    add_index :political_organizations, :name
    add_index :political_organizations, :status
  end
end
