json.helps do
  json.array! @helps do |help|
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
