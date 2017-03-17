class Payment < ApplicationRecord
  belongs_to :user
  acts_as_paranoid
  validates :user_id, :openid, :transaction_id, :total_fee, :time_end, :result_code, presence: true
end
# user_id	references	用户id
# openid	integer	微信用户开放编号
# transaction_id	string	交易编号
# total_fee	integer	订单金额
# time_end	string	支付完成时间
# result_code	string	业务结果
# deleted_at	datetime	删除时间

