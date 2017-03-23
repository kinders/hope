json.array! @todos do |todo|
  json.todos do
    json.id todo.id
    json.content todo.content
    json.user_id todo.user_id
    friendship = Friendship.find_by(user_id: @user.id, friend_id: todo.user_id)
    json.nickname friendship.nickname
    json.created_at todo.created_at.strftime("%F %T")
  end
end
json.array! @helps do |help|
  json.helps do
    json.id help.id
    json.content help.content
    json.receiver_id help.receiver_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: help.receiver_id)
      json.nickname friendship.nickname
    else
      json.nickname User.find_by(id: help.receiver_id).nickname
    end
    json.created_at help.created_at.strftime("%F %T")
  end
end
json.array! @friendships do |friendship|
  json.friendships do
    json.user_id friendship.friend_id
    json.nickname friendship.nickname 
  end
end
json.array! @groups do |group|
  json.groups do
    json.(group, :id, :name)
  end
end
json.array! @groups_helps do |groups_help|
  json.groups_help do
    json.id groups_help.id
    json.content groups_help.content
    json.group_id groups_help.group_id
    json.name groups_help.group.name
    json.created_at groups_help.created_at.strftime("%F %T")
  end
end
