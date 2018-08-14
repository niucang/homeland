class AddIsWuyeToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :is_wuye, :boolean, default: false
  end
end
