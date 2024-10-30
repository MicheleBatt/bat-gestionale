class AddNotNullValidationControlsToLastNameOnUsers < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :last_name, :string, null: false
  end
end
