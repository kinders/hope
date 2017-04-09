class Friendship < ApplicationRecord
  belongs_to :user
  acts_as_paranoid
  validates :user_id, :friend_id,  presence: true
end
# user_id	references	所有者
# friend_id	integer	朋友
# nickname	string	朋友的昵称
# deleted_at	datetime	删除时间
