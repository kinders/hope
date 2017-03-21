class Todo < ApplicationRecord
  belongs_to :user
  belongs_to :group
  has_many :discussions
  acts_as_paranoid
  validates :user_id, :receiver_id, :content, presence: true
end
# user_id	references	所有者	可以给自己表达愿望，也可以把看到的别人愿望一键转给自己，但所有者也跟着改为自己
# receiver_id	references	接受者	
# grouptodo_id	references	群任务	方便群发愿望
# content	text	内容	一旦出现讨论，则内容无法更改。
# is_finish	boolean	是否关闭	是否关闭由所有者决定
# discussions_count integer 讨论的数量，默认为0
# deleted_at	datetime	删除时间	

