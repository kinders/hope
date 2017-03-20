json.array! @friend_todos do |friend_todo|
  json.friend_todos do
    json.id friend_todo.id
    json.user_id friend_todo.user_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend_todo.user_id)
      json.nickname friendship.nickname
    else
      json.nickname friend_todo.user.nickname
    end
    json.content friend_todo.content
    json.created_at friend_todo.created_at
  end
end
