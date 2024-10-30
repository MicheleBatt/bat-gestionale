class AddIndexesToExpenseItems < ActiveRecord::Migration[7.1]
  def change
    add_index :expense_items, :description
    add_index :expense_items, :color
  end
end
