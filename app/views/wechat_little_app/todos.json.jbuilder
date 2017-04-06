json.todos do
  json.array! @todos do |todo|
    json.id todo.id
    json.content todo.content
    json.user_id todo.user_id
    friendship = Friendship.find_by(user_id: @user.id, friend_id: todo.user_id)
    json.nickname friendship.nickname
    json.created_at todo.created_at.strftime("%F %T")
  end
end
