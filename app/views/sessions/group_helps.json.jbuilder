json.array! @helps_in_group do |help|
  json.helps_in_group do
    json.id help.id
    json.content help.content
    json.created_at help.created_at
  end
end
