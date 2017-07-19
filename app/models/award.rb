class Award < ApplicationRecord
  belongs_to :user
  acts_as_paranoid
  validates :user_id, :sender_id, :content, presence: true
end
# user_id	references	所有者	可以给自己表达愿望，也可以把看到的别人愿望一键转给自己，但所有者也跟着改为自己
# sender_id	integer	接受者	
# content	text	内容	一旦出现讨论，则内容无法更改。
# deleted_at	datetime	删除时间	

