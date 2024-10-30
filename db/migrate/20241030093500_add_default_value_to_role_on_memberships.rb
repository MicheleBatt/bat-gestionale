class AddDefaultValueToRoleOnMemberships < ActiveRecord::Migration[7.1]
  def change
    change_column :memberships, :role, :string, null: false, default: 'guest'
  end
end
