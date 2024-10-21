class CreateExpenseItems < ActiveRecord::Migration[7.1]
  def change
    create_table :expense_items do |t|
      t.string :description, null: false
      t.string :color, null: false

      t.timestamps
    end

    add_index :expense_items, :description, unique: true
    add_index :expense_items, :color, unique: true
  end
end
