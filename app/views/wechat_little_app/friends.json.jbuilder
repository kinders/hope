json.friendships do
  json.array! @friendships do |friendship|
    json.friend_id friendship.friend_id
    json.nickname friendship.nickname 
  end
end
