class CreateGrouptodos < ActiveRecord::Migration[5.0]
  def change
    create_table :grouptodos do |t|
      t.references :user, foreign_key: true
      t.references :group, foreign_key: true

      t.timestamps
    end
  end
end
