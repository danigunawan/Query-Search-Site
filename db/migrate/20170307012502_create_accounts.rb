class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :nickname
      t.string :token
      t.string :token_secret

      t.timestamps
    end
  end
end
