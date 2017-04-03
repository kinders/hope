json.discussion do
  json.array! @discussions do |discussion|
    json.todo_id discussion.todo_id
    json.user_id discussion.user_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: discussion.user_id)
      json.nickname friendship.nickname
    else
      json.nickname discussion.user.nickname
    end
    json.content discussion.content
    json.created_at discussion.created_at.strftime("%F %T")
  end
end
