class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.integer :user1_id, null: false
      t.integer :user2_id, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
