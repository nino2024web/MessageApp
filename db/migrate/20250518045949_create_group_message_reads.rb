class CreateGroupMessageReads < ActiveRecord::Migration[7.1]
  def up
    create_table :group_message_reads do |t|
      t.references :user,          null: false, foreign_key: { on_delete: :cascade }
      t.references :group_message, null: false, foreign_key: false # ← 単独FKは付けない
      t.references :chat_room,     null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :group_message_reads, %i[user_id group_message_id], unique: true, name: 'idx_gmr_user_msg'
  end

  def down
    remove_index :group_message_reads, name: 'idx_gmr_lookup'
    execute 'ALTER TABLE group_message_reads DROP CONSTRAINT IF EXISTS fk_gmr_msg_room'
    remove_index :group_messages, name: 'idx_group_messages_id_room'
    remove_index :group_message_reads, column: %i[user_id group_message_id]
    drop_table :group_message_reads
  end
end
