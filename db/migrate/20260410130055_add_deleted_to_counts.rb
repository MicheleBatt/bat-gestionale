class AddDeletedToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :deleted, :boolean, null: false, default: false
    add_index :counts, :deleted
  end
end
