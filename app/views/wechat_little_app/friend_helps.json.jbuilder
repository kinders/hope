json.array! @friend_helps do |friend_help|
  json.friend_helps do
    json.id friend_help.id
    json.user_id friend_help.receiver_id
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend_help.receiver_id)
      json.nickname friendship.nickname
    else
      json.nickname User.find_by(id: friend_help.receiver_id).nickname
    end
    json.content friend_help.content
    json.created_at friend_help.created_at.strftime("%F %T")
  end
end
