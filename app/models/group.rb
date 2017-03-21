class Group < ApplicationRecord
  belongs_to :user
  has_many :todos
  has_many :grouptodos
  acts_as_paranoid
  validates :user_id, :name, :friends_id, presence: true
end
# user_id	references	所有者	
# name	string	名称	
# friends_id	string	众多朋友id	用String.split(',')和Array.join(',')可以互相转换
# deleted_at	datetime	删除时间	

