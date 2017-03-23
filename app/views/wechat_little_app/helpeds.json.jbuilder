json.array! @helpeds do |helped|
  json.helpeds do
    json.id helped.id
    json.receiver_id helped.receiver_id 
    if friendship = Friendship.find_by(user_id: @user.id, friend_id: helped.receiver_id)
      json.nickname friendship.nickname
    else
      json.nickname User.find_by(id: helped.receiver_id).nickname
    end
    json.content helped.content
    json.updated_at helped.updated_at.strftime("%F %T")
  end
end
