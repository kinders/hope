class WechatLittleAppController < ApplicationController

  # get hello 首页，可用于测试服务是否正常
  def hello
    render plain: ''
    #render plain: '您好！欢迎使用“希望协作”小程序'
  end

  # post login 登录系统，取出token
  # params js_code
  def login
    js_code = params[:js_code]
    wx_user = WxPay::Service.authenticate_from_weapp(js_code)
    @user = User.find_by(openid: wx_user["openid"])
    token = SecureRandom.uuid.tr('-', '')
    unless @user
      @user.create(openid: wx_user["openid"], nickname: '未设置', end_time: Time.now + (60*60*24*10))
    end
    # 检查有效登录时限，超过时限则发起微信支付
    if @user.end_time > Time.now
      # 写入缓存
      # $redis.set(token, wx_user["session_key"] + "DELIMITER" + wx_user["openid"])
      $redis.set(token, wx_user["openid"])  # 因为不想解密那些敏感信息，就不来存储会话密钥了。
      # 转到 我的任务 页面
      render json: {result_code: "t", token: token, current_user: {id: @user.id, nickname: @user.nickname, end_time: @user.end_time.strftime("%F %T")}}
    else
      render json: {result_code: "expired", msg: '超过使用期限，请先充值'}
    end
  end

    # post wechat_pay 微信支付
    # params token
  def wechat_pay
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    pay_params = {
      body: '希望协助-服务资费',          # 商品名称
      out_trade_no: Time.now.to_i,   # 商户订单号
      total_fee: 100,              # 总金额
      spbill_create_ip: request.remote_ip(),  # 终端IP
      notify_url: 'https://my_site/notify', # 通知地址，是自己的路由
      trade_type: 'JSAPI', # could be "JSAPI", "NATIVE" or "APP",  交易类型
      openid: @user.openid # required when trade_type is `JSAPI` 用户开放编号
    }
    uo_result = WxPay::Service.invoke_unifiedorder pay_params # 统一下单，返回prepay_id等字段组成的散列表
  # required fields
  req_params = {
    prepayid: uo_result["prepay_id"],
    noncestr:  uo_result["nonce_str"]
  }
  # call generate_js_pay_req
  r = WxPay::Service.generate_js_pay_req req_params
  # {
  #   "appId": "wx020c5c792c8537de",
  #   "package": "prepay_id=wx20160902211806a11ccee7a20956539837",
  #   "nonceStr": "2vS5AJUD7uyaa5h9",
  #   "timeStamp": "1472822286",
  #   "signType": "MD5",
  #   "paySign": "A52433CB75CA8D58B67B2BB45A79AA01"
  # }

    # 将支付参数（5个参数和sign）返回给小程序，由小程序提起wx.requestPayment发起微信支付
    render json: r
  end

  # post notify 接收微信支付通知
  # params request
  def notify
    result = Hash.from_xml(request.body.read)["xml"]
    if WxPay::Sign.verify?(result)
      @user = User.find_by(openid: result["openid"])
      Payment.create(user_id: @user.id, openid: @user.openid, transaction_id: result["transaction_id"],total_fee: result["total_fee"],time_end: result["time_end"],result_code: result["result_code"])
      @user.update(end_time: Time.now + (60*60*24*10*result["total_fee"]))
      render :xml => {result_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      render :xml => {result_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  # get helps  主页数据，我的希望
  # params: token
  def helps
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @helps = Todo.where(user_id: @user.id, is_finish: false, grouptodo_id: nil).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helps": ['
    @helps.each do |help|
      text << '{'
      text << '"id": ' + help.id.to_s + ", "
      text << '"content": "' + help.content + '", '
      text << '"receiver_id": ' + help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: help.receiver_id)
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

  # get todos  任务列表
  # params: token
  def todos
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    # 我的未完成任务列表（朋友的，不包括陌生人的）
    @todos = Todo.where(user_id: @user.friendships.pluck(:friend_id), receiver_id: @user.id, is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"todos": ['
    @todos.each do |todo|
      text << '{'
      text << '"id": ' + todo.id.to_s + ", "
      text << '"content": "' + todo.content + '", '
      text << '"user_id": ' + todo.user_id + ', '
      friendship = Friendship.find_by(user_id: @user.id, friend_id: todo.user_id)
      text << '"nickname": "' + friendship.nickname + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @other_todos = Todo.where(receiver_id: @user.id, is_finish: false).where.not(user_id: @user.friendships.pluck(:friend_id).push(@user.id)).order(discussions_count: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"other_todos": ['
    @dones.each do |todo|
      text << '{'
      text << '"id": ' + todo.id.to_s + ", "
      text << '"content": "' + todo.content + '", '
      text << '"user_id": ' + todo.user_id + ', '
      text << '"nickname": "' + todo.user.nickname + '", '
      text << '"created_at": "' + todo.created_at.strftime("%F %T") + '"},'
      text << '"discussion_count": ' + todo.discussion_count.to_s + '},'
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @dones = Todo.where(receiver_id: @user.id, is_finish: true).where.not(user_id: @user.id).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"dones": ['
    @dones.each do |done|
      text << '{'
      text << '"id": ' + done.id.to_s + ", "
      text << '"content": "' + done.content + '", '
      text << '"user_id": ' + done.user_id + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: done.user_id)
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @helpeds = Todo.where(user_id: @user.id, is_finish: true).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helpeds": ['
    @helpeds.each do |helped|
      text << '{'
      text << '"id": ' + helped.id.to_s + ", "
      text << '"content": "' + helped.content + '", '
      text << '"receiver_id": ' + helped.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: helped.receiver_id)
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

  # get groups_helps  朋友群请求列表
  # params: token
  def groups_helps
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @groups_helps = Grouptodo.where(user_id: @user.id, is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"groups_helps": ['
    @groups_helps.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": "' + grouptodo.content + '", '
      text << '"group_id": ' + grouptodo.group_id + ', '
      text << '"name": "' + grouptodo.name + '", '
      text << '"created_at": "' + grouptodo.created_at.strftime("%F %T") + '"},'
    end
    text.chop!
    text << ']}'
    render plain: text
  #=end
  end

  # get strangers 查看与我有联系的陌生人
  # params token
  def strangers
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @strangers = Friendship.where(friend_id: @user.id).where.not(user_id: @user.friendships.pluck(:friend_id)).order(:nickname)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"strangers": ['
    @strangers.each do |stranger|
      text << '{'
      text << '"user_id": ' + stranger.user_id.to_s + ", "
      text << '"nickname": "' + stranger.user.nickname + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friendships = Friendship.where(user_id: @user.id)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friendships": ['
    @friendships.each do |friendship|
      text << '{'
      text << '"friend_id": ' + friendship.friend_id.to_s + ", "
      text << '"nickname": "' + friendship.nickname + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friend_todos = Todo.where(receiver_id: params[:friend_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_todos": ['
    @friend_todos.each do |friend_todo|
      text << '{'
      text << '"id": ' + friend_todo.id.to_s + ", "
      text << '"content": "' + friend_todo.content + '", '
      text << '"user_id": ' + friend_todo.user_id + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend_todo.user_id)
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friend_helps = Todo.where(user_id: params[:friend_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friend_helps": ['
    @friend_helps.each do |friend_help|
      text << '{'
      text << '"id": ' + friend_help.id.to_s + ", "
      text << '"content": "' + friend_help.content + '", '
      text << '"user_id": ' + friend_help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend_help.receiver_id)
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

  # get groups  群
  # params: token
  def groups
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    # 我的朋友圈列表
    @groups = Group.where(user_id: @user.id, deleted_at: nil).order(:name)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"groups": ['
    @groups.each do |group|
      text << '{'
      text << '"id": ' + group.id.to_s + ", "
      text << '"name": "' + group.name + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group = Group.find_by(id: params[:group_id])
    @friends_in_group = User.where(id: @group.friends_id.split(','))
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"friends_in_group": ['
    @friends_in_group.each do |friend|
      text << '{'
      text << '"user_id": ' + friend.id.to_s + ", "
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: friend.id)
        text << '"nickname": "' + friendship.nickname + '", '
      else
        text << '"nickname": "' + friend.nickname + '", '
      end
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group_helpeds = Grouptodo.where(user_id: @user.id, group_id: params[:group_id], is_finish: true).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"group_helpeds": ['
    @group_helpeds.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": "' + grouptodo.content + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group_helps = Grouptodo.where(user_id: @user.id, group_id: params[:group_id], is_finish: false).order(id: :desc)
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"group_helps": ['
    @group_helps.each do |grouptodo|
      text << '{'
      text << '"id": ' + grouptodo.id.to_s + ", "
      text << '"content": "' + grouptodo.content + '", '
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @helps_in_grouptodo = Todo.where(grouptodo_id: params[:grouptodo_id])
    # 适应腾讯X5浏览的[text/html]request，删除这段代码可以生成默认的json数据
#=begin
    text = '{"helps_in_grouptodo": ['
    @helps_in_grouptodo.each do |help|
      text << '{'
      text << '"id": ' + help.id.to_s + ", "
      text << '"receiver_id": ' + help.receiver_id.to_s + ', '
      if friendship = Friendship.find_by(user_id: @user.id, friend_id: help.receiver_id)
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

  # post new_friend 添加朋友
  # 参数：token, friend_id, nickname
  def new_friend
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    if params[:friend_id] == @user.id
      render json: {result_code: 'f', msg: '你是你最好的朋友！'}
      return
    end
    @friend = User.find_by(id: params[:friend_id])
    @friendship = Friendship.find_by(user_id: @user.id, friend_id: @friend.id)
    if @friendship
      render json: {result_code: 'f', msg: '已经是好友'}
    else
      f_nickname = params[:nickname] || @friend.nickname
      Friendship.create(user_id: @user.id, friend_id: @friend.id, nickname: f_nickname)
      render json: {id: @friend.id}
    end
  end

  # post delete_friend 删除朋友
  # 参数：token, friend_id
  def delete_friend
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friendship = Friendship.find_by(user_id: @user.id, friend_id: params[:friend_id])
    if @friendship
      @friendship.destroy
      render json: {result_code: "t"}
    else
      render json: {result_code: "f", msg: '没有这个好友'}
    end
  end

  # post new_group 新建朋友群
  # params: token friends_id name
  def new_group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    friends_id_params = params[:friends_id].split('_').sort
    if friends_id_params.size < 2
      render json: {result_code: 'f', msg: '群人数应该多于2个'}
      return
    end
    @group = Group.find_by(user_id: @user.id, friends_id: friends_id_params.join(','))
    if @group.deleted_at == nil
      render json: {result_code: 'f', msg: '不能重复创建该群'}
    elsif @group.deleted_at != nil
      @group.update(deleted_at: nil, name: params[:name])
      render json: {group_id: @new_group.id}
    else
      @new_group = Group.create(user_id: @user.id, name: params[:name], friends_id: friends_id_params.join(','))
      render json: {group_id: @new_group.id}
    end
  end

  # post delete_group 删除朋友群
  # 参数：token, group_id
  def delete_group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group = Group.find_by(user_id: @user.id, id: params[:group_id])
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
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group = Group.find_by(id: params[:group_id], user_id: @user.id)
    if @group.update(name: params[:name])
      render json: {result_code: 't'}
    end
  end

  # post new_help_to_friend 新建请求给朋友
  # params: token, receiver_id, content
  def new_help_to_friend
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @todo = Todo.create(user_id: @user.id, receiver_id: params[:receiver_id], content: params[:content], is_finish: false)
    render json: {id: @todo.id, created_at: @todo.created_at.strftime("%F %T")}
  end
  
  # post new_help_to_group 新建群请求
  # params: token, group_id, content
  def new_help_to_group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group = Group.find_by(id: params[:group_id], user_id: @user.id)
    if @group
      @grouptodo = Grouptodo.create(user_id: @user.id, group_id: @group.id, content: params[:content], is_finish: false)
      @group.friends_id.split(',').each do |group_friend_id|
        Todo.create(user_id: @user.id, receiver_id: group_friend_id, grouptodo_id: @grouptodo.id, content: params[:content], is_finish: false)
      end
      render json: {id: @grouptodo.id}
    else
      render json: {result_code: 'f', msg: '无法找到该朋友群'}
    end
  end

  # post new_nickname 更改昵称
  # params token, friend_id, nickname
  def new_nickname
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    if @user.id.to_s == params[:friend_id]
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

  # post close_grouptodo 关闭群请求 
  # params: token, grouptodo_id
  def close_grouptodo
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @grouptodo = Grouptodo.find_by(id: params[:grouptodo_id], user_id: @user.id)
    if @grouptodo
      Todo.where(grouptodo_id: params[:grouptodo_id]).update_all(is_finish: true)
      @grouptodo.update(is_finish: true)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', msg: '没有权限来关闭这个群请求。'}
    end
  end

  # post close_help  关闭请求
  # params token, todo_id
  def close_help
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @todo = Todo.find_by(id: params[:todo_id], user_id: @user.id)
    if @todo
      @discussion = Discussion.create(user_id: @user.id, todo_id: @todo.id, content: "关闭请求，感谢帮助！")
      @todo.update(is_finish: true)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', message: "没有权限关闭任务"}
    end
  end

  # post close_helps  关闭多个请求
  # params token, grouptodo_id, friend_ids
  def close_helps
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    if params[:friends_id].size == 1
      Todo.find_by(grouptodo_id: params[:groutodo_id], user_id: @user.id, receiver_id: params[:friends_id]).update(is_finish: true)
      render json: {result_code: 't'}
      return
    end
    @todos = Todo.where(grouptodo_id: params[:grouptodo_id], user_id: @user.id, receiver_id: params[:friends_id].split(','))
    if @todos.update_all(is_finish: true)
      render json: {result_code: 't'}
    else
      render json: {result_code: 'f', message: "没有权限关闭任务"}
    end
  end

  # post rehelp  重启请求
  # params token, todo_id
  def rehelp
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @todo = Todo.find_by(id: params[:todo_id], user_id: @user.id)
    if @todo
      @discussion = Discussion.create(user_id: @user.id, todo_id: @todo.id, content: "重开请求！")
      @todo.update(is_finish: false)
      render json: {result_code: 't'}
    else
      render json: { result_code: 'f', msg: "没有权限关闭任务"}
    end
  end

  # get todo  请求页面详情
  # params token, todo_id
  def todo
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @todo = Todo.find_by(id: params[:todo_id])
    @discussions = @todo.discussions
  end

  # post new_discussion  添加讨论
  # params token, todo_id, content
  def new_discussion
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @discussion = Discussion.create(user_id: @user.id, todo_id: params[:todo_id], content: params[:content])
    @todo = Todo.find_by(id: params[:todo_id])
    count = @todo.discussions_count
    count = count + 1
    @todo.update(discussions_count: count)
    render json: {id: @discussion.id}
  end

  # post new_group_discussion
  # params token, grouptodo_id, content
  def new_group_discussion
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    begin
      Todo.where(grouptodo_id: params[:grouptodo_id]).each do |todo|
        Discussion.create(user_id: @user.id, todo_id: todo.id, content: params[:content])
        count = todo.discussions_count
        count = count + 1
        todo.update(discussions_count: count)
      end
      render json: {result_code: 't'}
    rescue
      render json: {result_code: 'f', msg: 'quit in batch operation'}
    end
  end

  # post new_discussion  添加讨论
  # params token, todo_id, content
  def new_discussion
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {result_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @discussion = Discussion.create(user_id: @user.id, todo_id: params[:todo_id], content: params[:content])
    @todo = Todo.find_by(id: params[:todo_id])
    count = @todo.discussions_count
    count = count + 1
    @todo.update(discussions_count: count)
    render json: {id: @discussion.id}
  end

end
