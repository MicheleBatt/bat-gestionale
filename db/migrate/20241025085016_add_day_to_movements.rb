class AddDayToMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :movements, :day, :integer, null: false
    rename_column :movements, :year_month, :year_month_day
    add_index :movements, :day
  end
end
