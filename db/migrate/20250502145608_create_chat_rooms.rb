class CreateChatRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_rooms do |t|
      t.string :name
      t.integer :creator_id

      t.timestamps
    end
    add_foreign_key :chat_rooms, :users, column: :creator_id
  end
end
