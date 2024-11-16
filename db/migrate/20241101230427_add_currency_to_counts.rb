class AddCurrencyToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :currency, :string, null: false, default: 'EUR'
  end
end
