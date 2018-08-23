class AddContinuousDaysToCheckInRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :check_in_records, :coutinuous_days, :integer
  end
end
