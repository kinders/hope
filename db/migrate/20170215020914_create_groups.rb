class CreateGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :groups do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.string :friends_id
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :groups, :deleted_at
  end
end
