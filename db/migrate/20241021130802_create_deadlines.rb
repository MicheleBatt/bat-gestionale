class CreateDeadlines < ActiveRecord::Migration[7.1]
  def change
    create_table :deadlines do |t|
      t.string :description, null: false
      t.datetime :expired_at, null: false
      t.integer :year, null: false

      t.timestamps
    end

    add_index :deadlines, :description
    add_index :deadlines, :expired_at
    add_index :deadlines, :year
    add_index :deadlines, [:year, :description], unique: true
  end
end
