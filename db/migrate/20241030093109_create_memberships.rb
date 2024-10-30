class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end
    add_index :memberships, :role
    add_index :memberships, [:user_id, :organization_id], unique: true
  end
end
