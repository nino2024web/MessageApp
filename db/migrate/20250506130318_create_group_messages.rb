class CreateGroupMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :group_messages do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true

      t.timestamps
    end
  end
end
