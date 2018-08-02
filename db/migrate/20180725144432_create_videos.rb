class CreateVideos < ActiveRecord::Migration[5.2]
  def change
    create_table :videos do |t|
      t.string :content, nil: false
      t.belongs_to :user
      t.timestamps
    end
  end
end
