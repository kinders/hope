class GroupsController < ApplicationController

  # get groups  群
  # params: token
  def groups
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    # 我的朋友圈列表
    @groups = Group.where(user_id: user_id, deleted_at: nil).order(:name)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"groups": [ '
    @groups.each do |group|
      text << '{'
      text << '"id": ' + group.id.to_s + ", "
      text << '"name": "' + group.name + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get group 查看群成员
  # prams: token group_id
  def group
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group = Group.find_by(id: params[:group_id])
    @friends_in_group = User.where(id: @group.friends_id.split(','))
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"group": [ '
    @friends_in_group.each do |friend|
      text << '{'
      text << '"user_id": ' + friend.id.to_s + ", "
      helps_length = Todo.where(user_id: user_id, receiver_id: friend.id, is_finish: false).count
      text << '"helps_length": ' + helps_length.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: friend.id)
        text << '"nickname": "' + friendship.nickname + '"},'
      else
        text << '"nickname": "' + friend.nickname + '"},'
      end
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end


  # post new_group 新建朋友群
  # params: token friends_id name
  def new_group
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    friends_id_params = params[:friends_id].split('_').sort
    if friends_id_params.size < 2
      render json: {result_code: 'f', msg: '群人数应该多于2个'}
      return
    end
    @group = Group.find_by(user_id: user_id, friends_id: friends_id_params.join(','))
    if @group && @group.deleted_at == nil
      render json: {result_code: 'f', msg: '不能重复创建该群'}
    elsif @group && @group.deleted_at != nil
      @group.update(deleted_at: nil, name: params[:name])
      render json: {group_id: @group.id}
    else
      @new_group = Group.create(user_id: user_id, name: params[:name], friends_id: friends_id_params.join(','))
      render json: {group_id: @new_group.id}
    end
  end
  
  # post new_members 为朋友群添加成员
  # params: token friends_id group_id
  def new_members
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group = Group.find_by(user_id: user_id, id: params[:group_id])
    friends_id_params = params[:friends_id].sort
    if @group 
      @group.update(friends_id: friends_id_params.join(',')) 
      render json: {result_code: "t"}
    end
  end
  
  # post delete_group 删除朋友群
  # 参数：token, group_id
  def delete_group
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group = Group.find_by(user_id: user_id, id: params[:group_id])
    if @group
      @group.update(deleted_at: Time.now)
      render json: {result_code: "t"}
    else
      render json: {result_code: "f", msg: '没有这个朋友圈'}
    end
  end
  
  # post new_groupname  更改群名称
  # params token, group_id, name
  def new_groupname
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @group = Group.find_by(id: params[:group_id], user_id: user_id)
    if @group && @group.update(name: params[:name])
      render json: {result_code: 't'}
    end
  end

end
