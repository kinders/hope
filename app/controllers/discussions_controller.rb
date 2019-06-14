class DiscussionsController < ApplicationController


  # get todo  请求页面的讨论详情
  # params token, todo_id
  def todo
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @todo = Todo.find_by(id: params[:todo_id])
    @discussions = @todo.discussions
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"todo": { "receiver_id": ' + @todo.receiver_id.to_s + ', '
    if friendship = Friendship.find_by(user_id: user_id, friend_id: @todo.receiver_id)
      text << '"receiver_nickname": "' + friendship.nickname + '", '
    else
      text << '"receiver_nickname": "' + User.find(@todo.receiver_id).nickname + '", '
    end
    text << '"content": ' + @todo.content.inspect + ', '
    text << '"is_finish": "' + @todo.is_finish.to_s + '", '
    text << '"created_at": "' + @todo.created_at.strftime("%F %T") + '" }'
    text << ', "discussions": [ '
    @discussions.each do |discussion|
      text << '{'
      text << '"todo_id": ' + discussion.todo_id.to_s + ", "
      text << '"content": ' + discussion.content.inspect + ', '
      text << '"user_id": ' + discussion.user_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: discussion.user_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + discussion.user.nickname + '", '
      end
      text << '"created_at": "' + discussion.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # post new_discussion  添加讨论
  # params token, todo_id, content
  def new_discussion
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @discussion = Discussion.create(user_id: user_id, todo_id: params[:todo_id], content: params[:content])
    @todo = Todo.find_by(id: params[:todo_id])
    count = @todo.discussions_count
    count = count + 1
    @todo.update(discussions_count: count)
    render json: {id: @discussion.id}
  end

  # post new_group_discussion 群发讨论
  # params token, grouptodo_id, content
  def new_group_discussion
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    begin
      Todo.where(grouptodo_id: params[:grouptodo_id]).each do |todo|
        Discussion.create(user_id: user_id, todo_id: todo.id, content: params[:content])
        count = todo.discussions_count
        count = count + 1
        todo.update(discussions_count: count)
      end
      render json: {result_code: 't'}
    rescue
      render json: {result_code: 'f', msg: 'quit in batch operation'}
    end
  end

  # get hot_discussions
  # params: token
  def hot_discussions
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    helps = Todo.where(user_id: user_id, is_finish: false).or(Todo.where(receiver_id: user_id, is_finish: false)).pluck(:id)
    @discussions = Discussion.where(todo_id: helps).where.not(user_id: user_id).order(id: :desc).first(500)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"hot_discussions": [ '
    @discussions.each do |discussion|
      text << '{'
      text << '"id": ' + discussion.id.to_s + ', '
      text << '"todo_id": ' + discussion.todo_id.to_s + ', '
      text << '"content": ' + discussion.content.inspect + ', '
      text << '"user_id": ' + discussion.user_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: discussion.user_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + discussion.user.nickname + '", '
      end
      text << '"created_at": "' + discussion.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

end
