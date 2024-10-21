class AddMonthToDeadlines < ActiveRecord::Migration[7.1]
  def change
    add_column :deadlines, :month, :integer, null: false
    add_index :deadlines, :month
  end
end
