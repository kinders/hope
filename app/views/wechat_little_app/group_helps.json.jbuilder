json.array! @group_helps do |grouptodo|
  json.group_helps do
    json.id grouptodo.id
    json.content grouptodo.content
    json.created_at grouptodo.created_at
  end
end
