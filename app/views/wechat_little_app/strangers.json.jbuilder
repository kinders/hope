json.strangers do
  json.array! @strangers do |stranger|
    json.user_id stranger.friend_id
    json.nickname stranger.nickname 
  end
end
