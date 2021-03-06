json.dones do
  json.array! @dones do |done|
    json.id done.id
    json.user_id done.user_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: done.user_id)
      json.nickname friendship.nickname
    else
      json.nickname done.user.nickname
    end
    json.content done.content
    json.created_at done.created_at.strftime("%F %T")
  end
end
