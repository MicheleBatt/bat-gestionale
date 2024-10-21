class CreateCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :counts do |t|
      t.string :name, null: false
      t.text :description
      t.string :iban
      t.float :initial_amount, null: false, default: 0

      t.timestamps
    end

    add_index :counts, :name, unique: true
  end
end
