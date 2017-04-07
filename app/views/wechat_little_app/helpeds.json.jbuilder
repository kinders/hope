json.helpeds do
  json.array! @helpeds do |helped|
    json.id helped.id
    json.receiver_id helped.receiver_id 
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: helped.receiver_id)
      json.nickname friendship.nickname
    else
      json.nickname User.find_by(id: helped.receiver_id).nickname
    end
    json.content helped.content
    json.created_at  helped.created_at.strftime("%F %T")
  end
end
