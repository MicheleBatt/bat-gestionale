class CreateMetalValues < ActiveRecord::Migration[7.1]
  def change
    create_table :metal_values do |t|
      t.string :metal, null: false
      t.float :value, null: false
      t.float :karat, null: false
      t.string :italian_name, null: false

      t.timestamps
    end

    add_index :metal_values, :metal
    add_index :metal_values, :value
    add_index :metal_values, :karat
    add_index :metal_values, [:metal, :karat], unique: true
  end
end
