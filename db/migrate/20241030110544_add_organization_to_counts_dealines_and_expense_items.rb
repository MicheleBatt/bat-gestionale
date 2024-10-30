class AddOrganizationToCountsDealinesAndExpenseItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :counts, :organization, null: true, foreign_key: true
    add_reference :deadlines, :organization, null: true, foreign_key: true
    add_reference :expense_items, :organization, null: true, foreign_key: true
  end
end
