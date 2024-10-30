class AddCountTypeToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :count_type, :string, null: false, default: 'bank_account'
    add_index :counts, :count_type
  end
end
