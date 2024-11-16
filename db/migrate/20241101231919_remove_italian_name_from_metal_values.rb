class RemoveItalianNameFromMetalValues < ActiveRecord::Migration[7.1]
  def change
    remove_column :metal_values, :italian_name
  end
end
