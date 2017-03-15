class AddSearchableInAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :searchable, :boolean, default: true
    add_column :accounts, :restart, :string
  end
end
