json.array! @group_helpeds do |grouptodo|
  json.group_helpeds do
    json.id grouptodo.id
    json.content grouptodo.content
    json.created_at grouptodo.created_at.strftime("%F %T")
  end
end

