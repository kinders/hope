json.array! @friends_in_group do |friend|
  json.group do
    json.user_id @friend.user_id
    json.nickname @friend.nickname
  end
end
