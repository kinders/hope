json.helps_in_grouptodo do
  json.array! @helps_in_grouptodo do |todo|
    json.id todo.id
    json.receiver_id todo.receiver_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: todo.receiver_id)
      json.nickname friendship.nickname
    else
      json.nickname User.find_by(id: todo.receiver_id).nickname
    end
    json.is_finish todo.is_finish
  end
end
