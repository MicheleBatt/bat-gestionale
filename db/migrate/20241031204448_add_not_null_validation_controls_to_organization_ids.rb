class AddNotNullValidationControlsToOrganizationIds < ActiveRecord::Migration[7.1]
  def change
    change_column :counts, :organization_id, :bigint, null: false
    change_column :deadlines, :organization_id, :bigint, null: false
    change_column :expense_items, :organization_id, :bigint, null: false
  end
end
