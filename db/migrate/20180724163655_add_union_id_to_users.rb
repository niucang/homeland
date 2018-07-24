class AddUnionIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unionid, :string
    add_index :users, :unionid
  end
end
