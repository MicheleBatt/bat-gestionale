class AddMetalValueIdToMovements < ActiveRecord::Migration[7.1]
  def change
    add_reference :movements, :metal_value, null: true, foreign_key: true
  end
end
