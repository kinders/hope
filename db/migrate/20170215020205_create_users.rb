class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :openid
      t.string :nickname
      t.datetime :end_time
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :users, :openid
    add_index :users, :end_time
    add_index :users, :deleted_at
  end
end
