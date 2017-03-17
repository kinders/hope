class CreateFriendships < ActiveRecord::Migration[5.0]
  def change
    create_table :friendships do |t|
      t.references :user, foreign_key: true
      t.integer :friend_id
      t.string :nickname
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :friendships, :friend_id
    add_index :friendships, :deleted_at
  end
end
