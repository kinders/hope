class RemoveGroupIdFromTodos < ActiveRecord::Migration[5.0]
  def change
    remove_reference :todos, :group, index: true
  end
end
