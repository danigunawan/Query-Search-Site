class AddGraphDataToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :graph_data, :text
  end
end
