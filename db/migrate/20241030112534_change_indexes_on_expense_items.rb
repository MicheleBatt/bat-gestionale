class ChangeIndexesOnExpenseItems < ActiveRecord::Migration[7.1]
  def change
    remove_index :expense_items, :description
    remove_index :expense_items, :color
    add_index :expense_items, [:description, :organization_id], unique: true
    add_index :expense_items, [:color, :organization_id], unique: true
  end
end
