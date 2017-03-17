class AddGrouptodoToTodos < ActiveRecord::Migration[5.0]
  def change
    add_reference :todos, :grouptodo, foreign_key: true
  end
end
