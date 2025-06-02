class CreateGroupMessageReads < ActiveRecord::Migration[7.1]
  def change
    create_table :group_message_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group_message, null: false, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true

      t.timestamps
    end

    add_index :group_message_reads, %i[user_id group_message_id], unique: true
  end
end
