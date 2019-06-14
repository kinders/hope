class GrouptodosController < ApplicationController

  # get groups_helps  所有朋友群请求列表
  # params: token
  def groups_helps
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @groups_helps = Grouptodo.where(user_id: user_id, is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"groups_helps": [ '
    @groups_helps.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": ' + grouptodo.content.inspect + ', '
      text << '"group_id": ' + grouptodo.group_id.to_s + ', '
      text << '"name": "' + grouptodo.group.name + '", '
      text << '"created_at": "' + grouptodo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # get group_helpeds 查看一个群里已经实现的群请求
  # params: token, group_id
  def group_helpeds
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group_helpeds = Grouptodo.where(user_id: user_id, group_id: params[:group_id], is_finish: true).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"group_helpeds": [ '
    @group_helpeds.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": ' + grouptodo.content.inspect + ', '
      text << '"created_at": "' + grouptodo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get group_helps 查看一个群里未实现的群请求
  # params: token, group_id
  def group_helps
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group_helps = Grouptodo.where(user_id:user_id, group_id: params[:group_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"group_helps": [ '
    @group_helps.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": ' + grouptodo.content.inspect + ', '
      text << '"created_at": "' + grouptodo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get helps_in_grouptodo 查看群请求完成情况
  # params grouptodo_id
  def helps_in_grouptodo
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @helps_in_grouptodo = Todo.where(grouptodo_id: params[:grouptodo_id])
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helps_in_grouptodo": [ '
    @helps_in_grouptodo.each do |help|
      text << '{'
      text << '"id": ' + help.id.to_s + ", "
      text << '"receiver_id": ' + help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: help.receiver_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + User.find_by(id: help.receiver_id).nickname + '", '
      end
      text << '"is_finish": "' + help.is_finish.to_s + '", '
      text << '"created_at": "' + help.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # post new_help_to_group 新建群请求
  # params: token, group_id, content
  def new_help_to_group
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group = Group.find_by(id: params[:group_id], user_id: user_id)
    if @group
      @grouptodo = Grouptodo.create(user_id: user_id, group_id: @group.id, content: params[:content], is_finish: false)
      @group.friends_id.split(',').each do |group_friend_id|
        Todo.create(user_id: user_id, receiver_id: group_friend_id, grouptodo_id: @grouptodo.id, content: params[:content], is_finish: false)
      end
      render json: {id: @grouptodo.id}
    else
      render json: {result_code: 'f', msg: '无法找到该朋友群'}
    end
  end

  # post close_grouptodo 关闭群请求 
  # params: token, grouptodo_id
  def close_grouptodo
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @grouptodo = Grouptodo.find_by(id: params[:grouptodo_id], user_id: user_id)
    if @grouptodo
      Todo.where(grouptodo_id: params[:grouptodo_id]).update_all(is_finish: true, updated_at: Time.now)
      @grouptodo.update(is_finish: true)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', msg: '没有权限来关闭这个群请求。'}
    end
  end

  # post open_grouptodo 开启群请求 
  # params: token, grouptodo_id
  def open_grouptodo
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @grouptodo = Grouptodo.find_by(id: params[:grouptodo_id], user_id: user_id)
    if @grouptodo
      @grouptodo.update(is_finish: false)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', msg: '没有权限来开启这个群请求。'}
    end
  end

  # post add_friends_to_grouptodo,将遗漏的队员添加到组任务中。
  # params: token, grouptodo_id, friends_ids
  def add_friends_to_grouptodo
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @grouptodo = Grouptodo.find(params[:grouptodo_id])
    @grouptodo.update(is_finish: false) if @grouptodo.is_finish == true
    params[:friends_id].to_a.each{ |f|
      Todo.create(user_id: user_id, receiver_id: f.to_i, content: @grouptodo.content, grouptodo_id: @grouptodo.id, is_finish: false)
    }
    render json: { result_code: 't' }
  end

end
