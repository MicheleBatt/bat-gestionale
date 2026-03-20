class CreateMetalPriceHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :metal_price_histories do |t|
      t.string :metal, null: false
      t.float :karat, null: false
      t.float :price_per_gram, null: false
      t.date :recorded_at, null: false

      t.timestamps
    end

    add_index :metal_price_histories, [:metal, :karat, :recorded_at], unique: true, name: 'idx_metal_price_histories_unique'
    add_index :metal_price_histories, :recorded_at
  end
end
