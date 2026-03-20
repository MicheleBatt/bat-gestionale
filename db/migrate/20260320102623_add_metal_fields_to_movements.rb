class AddMetalFieldsToMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :movements, :karat, :float
    add_column :movements, :price_at_transaction, :float
  end
end
