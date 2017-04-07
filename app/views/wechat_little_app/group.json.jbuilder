json.group do
  json.array! @friends_in_group do |friend|
    json.user_id @friend.id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend.id)
      json.nickname friendship.nickname
    else
      json.nickname friend.nickname
    end
  end
end
