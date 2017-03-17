class Discussion < ApplicationRecord
  belongs_to :user
  belongs_to :todo
  acts_as_paranoid
  validates :user_id, :todo_id, :content, presence: true
end
# user	references	所有者	
# todo_id	references	属于某个愿望	
# content	text	内容	愿望的提出者和接收者之间的讨论将提示对方，而其他人的讨论则只是显示在页面之中。
# deleted_at	datetime	删除时间	

