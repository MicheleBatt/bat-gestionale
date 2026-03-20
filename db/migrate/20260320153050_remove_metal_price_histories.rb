class RemoveMetalPriceHistories < ActiveRecord::Migration[7.1]
  def change
    drop_table :metal_price_histories
    add_column :metal_values, :recorded_at, :date, null: true
    remove_index :metal_values, name: "index_metal_values_on_metal_and_karat"

    add_index :metal_values, [:metal, :karat, :recorded_at], unique: true
    add_index :metal_values, :recorded_at
  end
end
