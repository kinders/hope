class ChangeTodos < ActiveRecord::Migration[5.0]
  def change
    remove_column :todos, :is_finish
    add_column :todos, :finished_at, :datetime
  end
end
