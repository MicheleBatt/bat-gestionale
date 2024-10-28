class AddMonitoringScopeToCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :counts, :monitoring_scope, :string, null: false, default: 'monthly'
    add_index :counts, :monitoring_scope
  end
end
