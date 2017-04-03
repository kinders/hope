json.other_todos do
  json.array! @other_todos do |todo|
    json.id todo.id
    json.content todo.content
    json.user_id todo.user_id
    json.nickname todo.user.nickname
    json.created_at todo.created_at.strftime("%F %T")
    json.discussion_count todo.discussions_count
  end
end
