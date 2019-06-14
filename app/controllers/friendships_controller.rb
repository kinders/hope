class FriendshipsController < ApplicationController

  # get strangers 查看与我有联系的陌生人
  # params token
  def strangers
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    friendship_ids = Friendship.where(user_id: user_id).pluck(:friend_id)
    @strangers = Friendship.where(friend_id: user_id).where.not(user_id: friendship_ids).order(:nickname)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"strangers": [ '
    @strangers.each do |stranger|
      text << '{'
      text << '"user_id": ' + stranger.user_id.to_s + ", "
      text << '"nickname": "' + stranger.user.nickname + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get friends  朋友列表
  # params: token
  def friends
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @friendships = Friendship.where(user_id: user_id)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friendships": [ '
    @friendships.each do |friendship|
      text << '{'
      text << '"friend_id": ' + friendship.friend_id.to_s + ", "
      helps_length = Todo.where(user_id: friendship.user_id, receiver_id: friendship.friend_id, is_finish: false).count
      text << '"helps_length": ' + helps_length.to_s + ', '
      text << '"nickname": "' + friendship.nickname + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # post new_friend 添加朋友
  # 参数：token, friend_id, nickname, is_fiction
  def new_friend
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    if params[:is_fiction] == '1'
      @friend = User.create(openid: 'fiction' + user_id.to_s, nickname: params[:nickname], end_time: Time.now)
      Friendship.create(user_id: user_id, friend_id: @friend.id, nickname: params[:nickname])
      render json: {id: @friend.id}
      return
    end
    if params[:friend_id] == user_id
      render json: {result_code: 'f', msg: '你是你最好的朋友！'}
      return
    end
    @friend = User.find_by(id: params[:friend_id])
    @friendship = Friendship.find_by(user_id: user_id, friend_id: @friend.id)
    if @friendship
      render json: {result_code: 'f', msg: '已经是好友'}
    else
      f_nickname = params[:nickname] || @friend.nickname
      Friendship.create(user_id: user_id, friend_id: @friend.id, nickname: f_nickname)
      render json: {id: @friend.id}
    end
  end
  
  # post delete_friend 删除朋友
  # 参数：token, friend_id
  def delete_friend
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @friendship = Friendship.find_by(user_id: user_id, friend_id: params[:friend_id])
    if @friendship
      @friendship.destroy
      render json: {result_code: "t"}
    else
      render json: {result_code: "f", msg: '没有这个好友'}
    end
  end

  # post new_nickname 更改昵称
  # params token, friend_id, nickname
  def new_nickname
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(id: user_id)
    if @user && @user.id.to_s == params[:friend_id]
      @user.update(nickname: params[:nickname])
      render json: {result_code: 't'}
      return
    end
    @friendship = Friendship.find_by(user_id: @user.id, friend_id: params[:friend_id])
    unless @friendship
      render json: {msg: '您没有这个朋友'}
      return
    end
    @friendship.update(nickname: params[:nickname])
    render json: {result_code: 't'}
  end

end
