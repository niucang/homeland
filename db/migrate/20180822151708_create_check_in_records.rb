class CreateCheckInRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :check_in_records do |t|
      t.belongs_to :user
      t.timestamps

      t.index :created_at
    end
  end
end
