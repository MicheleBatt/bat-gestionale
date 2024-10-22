class AddYearMonthToMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :movements, :year_month, :integer, null: false
    add_index :movements, :year_month
  end
end
