class AddMobilePhoneToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :mobile_phone, :string
    add_index :users, :mobile_phone
  end
end
