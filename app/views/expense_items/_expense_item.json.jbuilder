json.extract! expense_item, :id, :description, :color, :created_at, :updated_at
json.url expense_item_url(expense_item, format: :json)
