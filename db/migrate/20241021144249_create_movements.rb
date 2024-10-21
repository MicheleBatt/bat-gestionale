class CreateMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :movements do |t|
      t.references :count, null: false, foreign_key: true
      t.references :expense_item, null: true, foreign_key: true
      t.float :amount, null: false
      t.string :causal, null: false
      t.string :movement_type, null: false
      t.datetime :emitted_at, null: false
      t.integer :year, null: false
      t.integer :month, null: false

      t.timestamps
    end

    add_index :movements, :year
    add_index :movements, :month
    add_index :movements, :emitted_at
    add_index :movements, :movement_type
  end
end
