module ExpenseItemsHelper
  def expense_items_for_select(organization = nil)
    expense_items = ExpenseItem.all
    expense_items = expense_items.where(organization_id: organization.id) if organization.present?
    expense_items = expense_items.order(description: :asc, id: :asc)
    expense_items.map{ | item | [item.description, item.id ]}
  end
end
