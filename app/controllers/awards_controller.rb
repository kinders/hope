class AwardsController < ApplicationController

  # post new_award
  # params: token, receiver_id, content
  def new_award
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @award= Award.create(user_id: params[:receiver_id], sender_id: user_id, content: params[:content])
    render json: {id: @award.id, created_at: @award.created_at.strftime("%F %T")}
  end
  
  # get awards
  # params: token
  def awards
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @count = Award.where(user_id: user_id).count
    @count_finished = Todo.where(receiver_id: user_id, is_finish: true).count
    @count_unfinish = Todo.where(receiver_id: user_id, is_finish: false).count
    @awards = Award.where(user_id: user_id).order(id: :desc).first(100)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"count_finished": ' + @count_finished.to_s + ', "count_unfinish": ' + @count_unfinish.to_s + ', "count": ' + @count.to_s + ', "awards": [ '
    @awards.each do |award|
      text << '{'
      text << '"id": ' + award.id.to_s + ", "
      text << '"content": ' + award.content.inspect + ', '
      text << '"sender_id": ' + award.sender_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: user_id, friend_id: award.sender_id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + User.find_by(id: award.sender_id).nickname + '", '
      end
      text << '"created_at": "' + award.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # get friend_awards
  # params: token friend_id
  def friend_awards
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @count = Award.where(user_id: params[:friend_id], sender_id: user_id).count
    @awards = Award.where(user_id: params[:friend_id], sender_id: user_id).order(id: :desc).first(100)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"count": ' + @count.to_s + ', "awards": [ '
    @awards.each do |award|
      text << '{'
      text << '"id": ' + award.id.to_s + ", "
      text << '"content": ' + award.content.inspect + ', '
      text << '"created_at": "' + award.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end
  
  # post delete_award
  # params token, award_id
  def delete_award
    # 检查 token 是否过期
    user_id = $redis.hget(params[:token], userid)
    unless user_id
      render json: {result_code: "bad token"}
      return
    end
    @award = Award.find_by(id: params[:award_id])
    if @award
      @award.destroy
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', message: "bad award"}
    end
  end

end
