class CreatePayments < ActiveRecord::Migration[5.0]
  def change
    create_table :payments do |t|
      t.references :user, foreign_key: true
      t.string :openid
      t.string :transaction_id
      t.integer :total_fee
      t.string :time_end
      t.string :result_code
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :payments, :openid
    add_index :payments, :deleted_at
  end
end
