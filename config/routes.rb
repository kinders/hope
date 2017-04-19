Rails.application.routes.draw do
  post 'login', to: 'wechat_little_app#login'
  post 'wechat_pay', to: 'wechat_little_app#wechat_pay'
  post 'notify', to: 'wechat_little_app#notify'
  get 'helps', to: 'wechat_little_app#helps'
  get 'todos', to: 'wechat_little_app#todos'
  get 'other_todos', to: 'wechat_little_app#other_todos'
  get 'dones', to: 'wechat_little_app#dones'
  get 'dones_in_date', to: 'wechat_little_app#dones_in_date'
  get 'helpeds', to: 'wechat_little_app#helpeds'
  get 'helpeds_in_date', to: 'wechat_little_app#helpeds_in_date'
  get 'groups_helps', to: 'wechat_little_app#groups_helps'
  get 'strangers', to: 'wechat_little_app#strangers'
  get 'friends', to: 'wechat_little_app#friends'
  get 'friend', to: 'wechat_little_app#friend'
  get 'friend_helps', to: 'wechat_little_app#friend_helps'
  get 'groups', to: 'wechat_little_app#groups'
  get 'group', to: 'wechat_little_app#group'
  get 'group_helpeds', to: 'wechat_little_app#group_helpeds'
  get 'groups_helps', to: 'wechat_little_app#groups_helps'
  get 'group_helps', to: 'wechat_little_app#group_helps'
  get 'helps_in_grouptodo', to: 'wechat_little_app#helps_in_grouptodo'
  post 'new_friend', to: 'wechat_little_app#new_friend'
  post 'delete_friend', to: 'wechat_little_app#delete_friend'
  post 'new_group', to: 'wechat_little_app#new_group'
  post 'new_members', to: 'wechat_little_app#new_members'
  post 'delete_group', to: 'wechat_little_app#delete_group'
  post 'new_groupname', to: 'wechat_little_app#new_groupname'
  post 'new_help_to_friend', to: 'wechat_little_app#new_help_to_friend'
  post 'new_help_to_friends', to: 'wechat_little_app#new_help_to_friends'
  post 'new_help_to_group', to: 'wechat_little_app#new_help_to_group'
  post 'new_nickname', to: 'wechat_little_app#new_nickname'
  post 'close_grouptodo', to: 'wechat_little_app#close_grouptodo'
  post 'open_grouptodo', to: 'wechat_little_app#open_grouptodo'
  post 'close_help', to: 'wechat_little_app#close_help'
  post 'close_helps', to: 'wechat_little_app#close_helps'
  post 'rehelp', to: 'wechat_little_app#rehelp'
  get 'todo', to: 'wechat_little_app#todo'
  post 'new_discussion', to: 'wechat_little_app#new_discussion'
  post 'new_group_discussion', to: 'wechat_little_app#new_group_discussion'
  root 'wechat_little_app#hello'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
