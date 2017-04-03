json.group_helps do
  json.array! @group_helps do |grouptodo|
    json.id grouptodo.id
    json.content grouptodo.content
    json.created_at grouptodo.created_at.strftime("%F %T")
  end
end
