json.array! @todos do |todo|
  json.todos do
    json.id todo.id
    json.content todo.content
    json.user_id todo.user_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: todo.user_id)
      json.nickname friendship.nickname
    else
      json.nickname todo.user.nickname
    end
    json.created_at todo.created_at
    json.is_top todo.is_top
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
    json.created_at help.created_at
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
json.array! @group_helps do |group_help|
  json.group_help do
    json.id group_help.id
    json.content group_help.content
    json.group_id group_help.group_id
    json.name Group.find_by(id: group_help.group_id).name
    json.created_at group_help.created_at
  end
end
