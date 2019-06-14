class TodosController < ApplicationController

  # get helps  我的希望
  # params: token
  def helps
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @helps = Todo.where(user_id: user_id, is_finish: false, grouptodo_id: nil).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helps": [ '
    @helps.each do |help|
      text << '{'
      text << '"id": ' + help.id.to_s + ", "
      text << '"content": ' + help.content.inspect + ', '
      text << '"receiver_id": ' + help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: help.receiver_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + User.find_by(id: help.receiver_id).nickname + '", '
      end
      text << '"created_at": "' + help.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  

  # get todos  我的任务列表
  # params: token
  def todos
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
	friend_ids = Friendship.where(user_id: user_id).pluck(:friend_id)
    # 我的未完成任务列表（朋友的，不包括陌生人的）
    @todos = Todo.where(user_id: friend_ids, receiver_id: user_id, is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"todos": [ '
    @todos.each do |todo|
      text << '{'
      text << '"id": ' + todo.id.to_s + ", "
      text << '"content": ' + todo.content.inspect + ', '
      text << '"user_id": ' + todo.user_id.to_s + ', '
      friendship_nickname = Friendship.find_by(user_id: user_id, friend_id: todo.user_id).nickname
      text << '"nickname": "' + friendship_nickname + '", '
      text << '"created_at": "' + todo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get other_todos 查看其他陌生人请我完成的任务
  # params token
  def other_todos
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
	friend_ids = Friendship.where(user_id: user_id).pluck(:friend_id)
    @other_todos = Todo.where(receiver_id: user_id, is_finish: false).where.not(user_id: friend_ids.push(user_id)).order(discussions_count: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"other_todos": [ '
    @other_todos.each do |todo|
      text << '{'
      text << '"id": ' + todo.id.to_s + ", "
      text << '"content": ' + todo.content.inspect + ', '
      text << '"user_id": ' + todo.user_id.to_s + ', '
      text << '"nickname": "' + todo.user.nickname + '", '
      text << '"created_at": "' + todo.created_at.strftime("%F %T") + '", '
      text << '"discussions_count": ' + todo.discussions_count.to_s + '},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get dones  查看我已经完成的任务
  # params: token
  def dones
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @dones = Todo.where(receiver_id: user_id, is_finish: true).where.not(user_id: user_id).order(id: :desc).first(100)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"dones": [ '
    @dones.each do |done|
      text << '{'
      text << '"id": ' + done.id.to_s + ", "
      text << '"content": ' + done.content.inspect + ', '
      text << '"user_id": ' + done.user_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: done.user_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + done.user.nickname + '", '
      end
      text << '"created_at": "' + done.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # get dones_in_date  按日期查看我已经完成的任务
  # params: token date
  def dones_in_date
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    year, month, day = params[:date].split('-')
    one_day = Time.new(year, month, day).all_day
    @dones = Todo.where(receiver_id: user_id, is_finish: true, created_at: one_day).where.not(user_id: user_id).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"dones": [ '
    @dones.each do |done|
      text << '{'
      text << '"id": ' + done.id.to_s + ", "
      text << '"content": ' + done.content.inspect + ', '
      text << '"user_id": ' + done.user_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: done.user_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + done.user.nickname + '", '
      end
      text << '"created_at": "' + done.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # get helpeds  查看别人已经帮我实现的愿望
  # params: token
  def helpeds
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @helpeds = Todo.where(user_id: user_id, is_finish: true).order(updated_at: :desc).first(100)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helpeds": [ '
    @helpeds.each do |helped|
      text << '{'
      text << '"id": ' + helped.id.to_s + ", "
      text << '"content": ' + helped.content.inspect + ', '
      text << '"receiver_id": ' + helped.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: helped.receiver_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + User.find_by(id: helped.receiver_id).nickname + '", '
      end
      text << '"created_at": "' + helped.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # get helpeds_in_date  按日期查看别人已经帮我实现的愿望
  # params: token date
  def helpeds_in_date
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    year, month, day = params[:date].split('-')
    one_day = Time.new(year, month, day).all_day
    @helpeds = Todo.where(user_id:user_id, is_finish: true, created_at: one_day).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helpeds": [ '
    @helpeds.each do |helped|
      text << '{'
      text << '"id": ' + helped.id.to_s + ", "
      text << '"content": ' + helped.content.inspect + ', '
      text << '"receiver_id": ' + helped.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: helped.receiver_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + User.find_by(id: helped.receiver_id).nickname + '", '
      end
      text << '"created_at": "' + helped.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
 

  # get friend 查看朋友主页——未实现的任务
  # params: token friend_id
  def friend
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @friend_todos = Todo.where(receiver_id: params[:friend_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_todos": [ '
    @friend_todos.each do |friend_todo|
      text << '{'
      text << '"id": ' + friend_todo.id.to_s + ", "
      text << '"content": ' + friend_todo.content.inspect + ', '
      text << '"user_id": ' + friend_todo.user_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: friend_todo.user_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + friend_todo.user.nickname + '", '
      end
      text << '"created_at": "' + friend_todo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
 

  # get friend_helps 查看朋友主页——未实现的请求
  # params: token friend_id
  def friend_helps
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @friend_helps = Todo.where(user_id: params[:friend_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_helps": [ '
    @friend_helps.each do |friend_help|
      text << '{'
      text << '"id": ' + friend_help.id.to_s + ", "
      text << '"content": ' + friend_help.content.inspect + ', '
      text << '"user_id": ' + friend_help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: friend_help.receiver_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + User.find_by(id: friend_help.receiver_id).nickname + '", '
      end
      text << '"created_at": "' + friend_help.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end


  # get friend_dones  查看朋友已经完成的任务
  # params: token friend_id
  def friend_dones
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @friend_dones = Todo.where(receiver_id: params[:friend_id], user_id: user_id, is_finish: true).order(updated_at: :desc).first(100)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_dones": [ '
    @friend_dones.each do |done|
      text << '{'
      text << '"id": ' + done.id.to_s + ", "
      text << '"content": ' + done.content.inspect + ', '
      text << '"receiver_id": ' + done.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: done.receiver_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + done.user.nickname + '", '
      end
      text << '"created_at": "' + done.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end


  # get friend_dones_in_date  按日期查看朋友已经完成的任务
  # params: token friend_id date
  def friend_dones_in_date
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    year, month, day = params[:date].split('-')
    if params[:start_date]
      start_year, start_month, start_day = params[:start_date].split('-')
      start_time = Time.new(start_year, start_month, start_day).at_beginning_of_day()
      end_time = Time.new(year, month, day).at_end_of_day()
      @friend_dones = Todo.where(receiver_id: params[:friend_id], user_id: user_id, is_finish: true, created_at: start_time..end_time).order(id: :desc)
    else
      one_day = Time.new(year, month, day).all_day
      @friend_dones = Todo.where(receiver_id: params[:friend_id], user_id: user_id, is_finish: true, created_at: one_day).order(id: :desc)
    end
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_dones": [ '
    @friend_dones.each do |done|
      text << '{'
      text << '"id": ' + done.id.to_s + ", "
      text << '"content": ' + done.content.inspect + ', '
      text << '"receiver_id": ' + done.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: done.user_id)
      text << '"nickname": "' + friendship.nickname + '", '
      else
      text << '"nickname": "' + done.user.nickname + '", '
      end
      text << '"created_at": "' + done.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end


  # post new_help_to_friend 新建请求给朋友
  # params: token, receiver_id, content
  def new_help_to_friend
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @todo = Todo.create(user_id:user_id, receiver_id: params[:receiver_id], content: params[:content], is_finish: false)
    render json: {id: @todo.id, created_at: @todo.created_at.strftime("%F %T")}
  end
  
  # post new_help_to_friends 新建请求给多个朋友
  # params: token, friends_id, content
  def new_help_to_friends
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    params[:friends_id].to_a.each{ |f|
      @todo = Todo.create(user_id: user_id, receiver_id: f.to_i, content: params[:content], is_finish: false)
    }
    render json: { result_code: 't' }
  end


  # post close_help  关闭请求
  # params token, todo_id
  def close_help
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @todo = Todo.find_by(id: params[:todo_id], user_id: user_id)
    if @todo
      @discussion = Discussion.create(user_id: user_id, todo_id: @todo.id, content: "关闭请求，感谢帮助！")
      @todo.update(is_finish: true)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', message: "没有权限关闭任务"}
    end
  end
  
  # post close_helps  关闭多个请求
  # params token, grouptodo_id, friends_id
  def close_helps
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    if params[:friends_id].size == 1
      Todo.find_by(grouptodo_id: params[:grouptodo_id], user_id: user_id, receiver_id: params[:friends_id]).update(is_finish: true)
      render json: {result_code: 't'}
      return
    end
    @todos = Todo.where(grouptodo_id: params[:grouptodo_id], user_id: user_id, receiver_id: params[:friends_id].split('_'))
    if @todos.any? && @todos.update_all(is_finish: true, updated_at: Time.now)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', message: "服务器拒绝关闭任务"}
    end
  end
  
  # post rehelp  重启请求
  # params token, todo_id
  def rehelp
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @todo = Todo.find_by(id: params[:todo_id], user_id: user_id)
    if @todo
      @discussion = Discussion.create(user_id: user_id, todo_id: @todo.id, content: "重开请求！")
      @todo.update(is_finish: false)
      render json: {result_code: 't'}
    else
      render json: { result_code: 'f', msg: "没有权限关闭任务"}
    end
  end


  # post search_todos
  # params: token, user_id, scope, start_date, end_date, searchword
  def search_todos
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    start_year, start_month, start_day = params[:start_date].split('-')
    end_year, end_month, end_day = params[:end_date].split('-')
    start_time = Time.new(start_year, start_month, start_day).at_beginning_of_day()
    end_time = Time.new(end_year, end_month, end_day).at_end_of_day()
    @todos = []
    case params[:scope]
    when "0"
      @todos = Todo.where(user_id: params[:user_id], receiver_id: user_id, is_finish: true, created_at: start_time..end_time).order(id: :desc)
    when "1"
      @todos = Todo.where(user_id: params[:user_id], receiver_id: user_id, is_finish: false, created_at: start_time..end_time).order(id: :desc)
    when "2"
      @todos = Todo.where(user_id: user_id, receiver_id: params[:user_id], is_finish: true, created_at: start_time..end_time).order(id: :desc)
    when "3"
      @todos = Todo.where(user_id: user_id, receiver_id: params[:user_id], is_finish: false, created_at: start_time..end_time).order(id: :desc)
    end  
  # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    i = 0
    text = '{"todos": [ '
    @todos.each do |todo|
      break if i == 100
      next if todo.content.scan(params[:searchword]).empty?
      text << '{'
      text << '"id": ' + todo.id.to_s + ", "
      text << '"content": ' + todo.content.inspect + ', '
      text << '"is_finish": ' + todo.is_finish.to_s + ', '
      text << '"user_id": ' + todo.user_id.to_s + ', '
      if user_id == todo.user_id
        text << '"user_nickname": "' + todo.user.nickname + '", '
      else
        friendship = Friendship.find_by(user_id: user_id, friend_id: todo.user_id)
        text << '"user_nickname": "' + friendship.nickname + '", '
      end
      text << '"receiver_id": ' + todo.receiver_id.to_s + ', '
      if user_id == todo.receiver_id
        text << '"receiver_nickname": "' + todo.user.nickname + '", '
      else
        friendship = Friendship.find_by(user_id: user_id, friend_id: todo.receiver_id)
        text << '"receiver_nickname": "' + friendship.nickname + '", '
      end
      text << '"created_at": "' + todo.created_at.strftime("%F %T") + '"},'
      i = i + 1
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
end
