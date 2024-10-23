class AddOrderingNumberToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :ordering_number, :integer, null: false, default: 0
    add_index :counts, :ordering_number
  end
end
