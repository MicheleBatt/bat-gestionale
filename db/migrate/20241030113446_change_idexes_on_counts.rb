class ChangeIdexesOnCounts < ActiveRecord::Migration[7.1]
  def change
    remove_index :counts, :name
    add_index :counts, :name
    add_index :counts, [:name, :organization_id], unique: true
  end
end
