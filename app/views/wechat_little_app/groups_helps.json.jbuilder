json.array! @groups_helps do |grouptodo|
  json.groups_helps do
    json.id grouptodo.id
    json.content grouptodo.content
    json.group_id grouptodo.group_id
    json.name grouptodo.group.name
    json.created_at grouptodo.created_at.strftime("%F %T")
  end
end
