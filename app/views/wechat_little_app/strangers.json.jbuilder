json.strangers do
  json.array! @strangers do |stranger|
    json.user_id stranger.user_id
    json.nickname stranger.user.nickname 
  end
end
