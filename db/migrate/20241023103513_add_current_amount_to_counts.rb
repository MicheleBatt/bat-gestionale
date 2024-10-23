class AddCurrentAmountToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :current_amount, :float, null: false, default: 0
    add_index :counts, :initial_amount
    add_index :counts, :current_amount
    add_index :movements, :amount
  end
end
