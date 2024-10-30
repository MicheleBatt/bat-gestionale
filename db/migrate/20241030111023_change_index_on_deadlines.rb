class ChangeIndexOnDeadlines < ActiveRecord::Migration[7.1]
  def change
    remove_index :deadlines, [:year, :description]
  end
end
