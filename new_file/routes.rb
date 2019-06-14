Rails.application.routes.draw do

  root 'weapp#hello'

  post 'login', to: 'weapp#login'
  post 'wechat_pay', to: 'weapp#wechat_pay'
  post 'notify', to: 'weapp#notify'
  
  get 'helps', to: 'todos#helps'
  get 'todos', to: 'todos#todos'
  get 'other_todos', to: 'todos#other_todos'
  get 'dones', to: 'todos#dones'
  get 'dones_in_date', to: 'todos#dones_in_date'
  get 'helpeds', to: 'todos#helpeds'
  get 'helpeds_in_date', to: 'todos#helpeds_in_date'
  get 'friend', to: 'todos#friend'
  get 'friend_helps', to: 'todos#friend_helps'
  get 'friend_dones', to: 'todos#friend_dones'
  get 'friend_dones_in_date', to: 'todos#friend_dones_in_date'
  post 'new_help_to_friend', to: 'todos#new_help_to_friend'
  post 'new_help_to_friends', to: 'todos#new_help_to_friends'
  post 'close_help', to: 'todos#close_help'
  post 'close_helps', to: 'todos#close_helps'
  post 'rehelp', to: 'todos#rehelp'
  post 'search_todos', to: 'todos#search_todos' 
    
  get 'strangers', to: 'friendships#strangers'
  get 'friends', to: 'friendships#friends'
  post 'new_friend', to: 'friendships#new_friend'
  post 'delete_friend', to: 'friendships#delete_friend'
  post 'new_nickname', to: 'friendships#new_nickname'
  
  get 'groups', to: 'groups#groups'
  get 'group', to: 'groups#group'
  post 'new_group', to: 'groups#new_group'
  post 'new_members', to: 'groups#new_members'
  post 'delete_group', to: 'groups#delete_group'
  post 'new_groupname', to: 'groups#new_groupname'

  get 'groups_helps', to: 'grouptodos#groups_helps'  
  get 'group_helpeds', to: 'grouptodos#group_helpeds'
  get 'group_helps', to: 'grouptodos#group_helps'
  get 'helps_in_grouptodo', to: 'grouptodos#helps_in_grouptodo'
  post 'new_help_to_group', to: 'grouptodos#new_help_to_group'
  post 'close_grouptodo', to: 'grouptodos#close_grouptodo'
  post 'open_grouptodo', to: 'grouptodos#open_grouptodo'
  post 'add_friends_to_grouptodo', to: 'grouptodos#add_friends_to_grouptodo'

  get 'todo', to: 'discussions#todo'
  post 'new_discussion', to: 'discussions#new_discussion'
  post 'new_group_discussion', to: 'discussions#new_group_discussion'
  get 'hot_discussions', to: 'discussions#hot_discussions'

  get 'awards', to: 'awards#awards'
  get 'friend_awards', to: 'awards#friend_awards'
  post 'new_award', to: 'awards#new_award'
  post 'delete_award', to: 'awards#delete_award'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '*other', to: 'weapp#hello'
  post '*other', to: 'weapp#hello'
  post '/', to: 'weapp#hello'
  
end
