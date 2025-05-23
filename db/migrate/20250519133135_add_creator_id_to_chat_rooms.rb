class AddCreatorIdToChatRooms < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_rooms, :creator_id, :integer
    add_foreign_key :chat_rooms, :users, column: :creator_id
  end
end
