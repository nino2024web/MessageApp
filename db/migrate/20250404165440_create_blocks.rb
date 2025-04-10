class CreateBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :blocks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blocked_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :blocks, %i[user_id blocked_user_id], unique: true
  end
end
