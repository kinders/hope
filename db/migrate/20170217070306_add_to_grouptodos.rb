class AddToGrouptodos < ActiveRecord::Migration[5.0]
  def change
    add_column :grouptodos, :content, :text
    add_column :grouptodos, :finished_at, :datetime
    add_column :grouptodos, :deleted_at, :datetime
    add_index :grouptodos, :deleted_at
  end
end
