class RenamePriceAtTransactionIntoPricePerGramAtTransactionOnMovements < ActiveRecord::Migration[7.1]
  def change
    rename_column :movements, :price_at_transaction, :price_per_gram_at_transaction
  end
end
