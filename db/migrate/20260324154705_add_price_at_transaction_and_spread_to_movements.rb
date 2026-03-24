class AddPriceAtTransactionAndSpreadToMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :movements, :price_at_transaction, :float
    add_column :movements, :spread, :float

    add_index :movements, :karat
    add_index :movements, :spread
    add_index :movements, :price_at_transaction
    add_index :movements, :price_per_gram_at_transaction
  end
end
