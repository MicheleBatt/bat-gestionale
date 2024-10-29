module ExpenseItemsHelper
  def expense_items_for_select(expense_items = ExpenseItem.all.order(description: :asc, id: :asc))
    expense_items.map{ | item | [item.description, item.id ]}
  end
end
