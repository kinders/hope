class ChangeTodosAndGrouptodos < ActiveRecord::Migration[5.0]
  def change
    remove_column :todos, :finished_at
    add_column :todos, :is_finish, :boolean
    remove_column :grouptodos, :finished_at
    add_column :grouptodos, :is_finish, :boolean
  end
end
