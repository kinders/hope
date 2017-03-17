class User < ApplicationRecord
  has_many :discussions
  has_many :friendships
  has_many :groups
  has_many :payments
  has_many :todo
  acts_as_paranoid
  validates :openid, :nickname, :end_time,  presence: true

end

# openid	string	微信开发id号
# nickname	string	自己的昵称
# end_time	datetime	30日内是否支付
# deleted_at	datetime	删除时间

