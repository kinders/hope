class CreateAwards < ActiveRecord::Migration[5.0]
  def change
    create_table :awards do |t|
      t.references :user, foreign_key: true
      t.integer :sender_id
      t.text :content
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :awards, :deleted_at
  end
end
