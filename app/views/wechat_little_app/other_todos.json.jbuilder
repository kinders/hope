json.array! @other_todos do |todo|
  json.other_todos do
    json.id todo.id
    json.content todo.content
    json.user_id todo.user_id
    json.nickname todo.user.nickname
    json.created_at todo.created_at
    json.is_top todo.is_top
  end
end
