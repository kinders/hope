class CreateTodos < ActiveRecord::Migration[5.0]
  def change
    create_table :todos do |t|
      t.references :user, foreign_key: true
      t.integer :receiver_id
      t.text :content
      t.boolean :is_finish
      t.boolean :is_top
      t.references :group, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :todos, :deleted_at
  end
end
