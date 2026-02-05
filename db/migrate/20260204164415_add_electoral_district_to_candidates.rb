class AddElectoralDistrictToCandidates < ActiveRecord::Migration[8.1]
  def change
    add_reference :candidates, :electoral_district, null: true, foreign_key: true, index: true
  end
end
