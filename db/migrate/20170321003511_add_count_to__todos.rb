class AddCountToTodos < ActiveRecord::Migration[5.0]
  def change
    remove_column :todos, :is_top
    add_column :todos, :discussions_count, :integer, default: 0
  end
end
