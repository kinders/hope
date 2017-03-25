json.array! @strangers do |stranger|
  json.strangers do
    json.user_id stranger.friend_id
    json.nickname stranger.nickname 
  end
end
