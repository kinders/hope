class Grouptodo < ApplicationRecord
  belongs_to :user
  belongs_to :group
  has_many :todos
  acts_as_paranoid
  validates :user_id, :group_id, presence: true
end
# user_id	references	所有者	
# group_id references	朋友圈
