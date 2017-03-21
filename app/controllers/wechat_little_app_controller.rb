class WechatLittleAppController < ApplicationController # class SessionsController < ApplicationController

  # post login 登录系统，取出token
  # params js_code
  def login
    js_code = params[:js_code]
    wx_user = WxPay::service.authenticate_from_weapp(js_code)
    @user = User.find_by(openid: wx_user[openid])
    token = SecureRandom.uuid.tr('-', '')
    unless @user
      @user.create(openid: wx_user[openid], end_time: Time.now + (60*60*24*30))
    end
    # 检查有效登录时限，超过时限则发起微信支付
    if @user.end_time > Time.now
      # 写入缓存
      # $redis.set(token, wx_user[session_key] + "DELIMITER" + wx_user[openid])
      $redis.set(token, wx_user[openid])  # 因为不想解密那些敏感信息，就不来存储会话密钥了。
      # 转到 我的任务 页面
      render json: {result_code: "t", token: token, current_user: {id: @user.id, nickname: @user.nickname, end_time: @user.end_time}}
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
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    pay_params = {
      body: '"希望"软件使用资费1元10天',          # 商品名称
      out_trade_no: Time.now.to_s,   # 商户订单号
      total_fee: 1,              # 总金额
      spbill_create_ip: '127.0.0.1',  # 终端IP
      notify_url: 'http://my_site/notify', # 通知地址，是自己的路由
      trade_type: 'JSAPI', # could be "JSAPI", "NATIVE" or "APP",  交易类型
      openid: @user.openid # required when trade_type is `JSAPI` 用户开放编号
    }
    uo_result = WxPay::Service.invoke_unifiedorder pay_params # 统一下单，返回prepay_id等字段组成的散列表
  # required fields
  req_params = {
    prepay_id: uo_result[:prepay_id],
    noncestr:  uo_result[:noncestr]
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
      @user = User.find_by(openid: result[:openid])
      Payment.create(user_id: @user.id, transaction_id: result[:transaction_id],total_fee: result[:total_fee],time_end: result[:time_end],result_code: result[:result_code])
      @user.update(end_time: Time.now + (60*60*24*10*result[:total_fee]))
      render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

  # get home  主页数据
  # params: token
  def home
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    # 我的未完成任务列表（朋友的，不包括陌生人的）
    @todos = Todo.where(user_id: @user.friendships.pluck(:friend_id), receiver_id: @user.id, is_finish: false).order(id: :desc)
    # 我提出的希望列表
    @helps = Todo.where(user_id: @user.id, is_finish: false).order(id: :desc)
    # 我的朋友列表
    @friendships = Friendship.where(user_id: @user.id).order(:nickname)
    # 我的朋友圈列表
    @groups = Group.where(user_id: @user.id).order(:name)
    @groups_helps = Grouptodo.where(user_id: @user.id, is_finish: false).order(id: :desc)
  end

  # get other_todos 查看其他陌生人请我完成的任务
  # params token
  def other_todos
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @other_todos = Todo.where(receiver_id: @user.id, is_finish: false).where.not(user_id: @user.friendships.pluck(:friend_id)).order(discussions_count: :desc)
  end

  # get dones  查看我已经完成的任务
  # params: token
  def dones
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @dones = Todo.where(receiver_id: @user.id, is_finish: true).order(id: :desc)
  end

  # get helpeds  查看别人已经帮我实现的愿望
  # params: token
  def helpeds
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @helpeds = Todo.where(user_id: @user.id, is_finish: true).order(id: :desc)
  end

  # get friend 查看朋友主页——未实现的任务
  # params: token friend_id
  def friend_todos
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friend_todos = Todo.where(receiver_id: params[:friend_id], is_finish: false).order(id: :desc)
  end

  # get friend_helps 查看朋友主页——未实现的请求
  # params: token friend_id
  def friend_helps
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friend_helps = Todo.where(user_id: params[:friend_id], is_finish: false).order(id: :desc)
  end

  # get group 查看群成员
  # prams: token group_id
  def group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group = Group.find_by(id: params(group_id))
    @friends_in_group = User.where(user_id: @group.friends_id.split('_')).order(nickname)
  end

  # get group_helpeds 查看一个群里已经实现的群请求
  # params: token, group_id
  def group_helpeds
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group_helpeds = Grouptodo.where(user_id: @user.id, group_id: params[:group_id], is_finish: true).order(id: :desc)
  end

  # get group_helps 查看一个群里未实现的群请求
  # params: token, group_id
  def group_helps
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @group_helps = Grouptodo.where(user_id: @user.id, group_id: params[:group_id], is_finish: false).order(id: :desc)
  end

  # get helps_in_grouptodo 查看群请求完成情况
  # params grouptodo_id
  def helps_in_grouptodo
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @helps_in_grouptodo = Todo.find_by(grouptodo_id: params[:grouptodo_id])
  end

  # post new_friend 添加朋友
  # 参数：token, friend_id, nickname
  def new_friend
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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
      render json: {return_code: "bad token"}
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

  # post new_group 新建朋友圈
  # params: token friends_id name
  def new_group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    friends_id_params = params[:friends_id].split(',').sort
    # print friends_id_params
    if friends_id_params.include?(@user.id.to_s)
      friends_id_params.delete(@user.id.to_s)
    end
    if friends_id_params.size < 2
      render json: {result_code: 'f', msg: '群人数应该多于2个'}
      return
    end
    
    @group = Group.find_by(user_id: @user.id, friends_id: friends_id_params.join(','))
    if @group
      render json: {result_code: 'f', msg: '不能重复创建该群'}
    else
      @new_group = Group.create(user_id: @user.id, name: params[:name], friends_id: friends_id_params.join(','))
      render json: {group_id: @new_group.id}
    end
  end

  # post new_groupname  更改群名称
  # params token, group_id, name
  def new_groupname
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friendship = Friendship.find_by(user_id: @user.id, friend_id: params[:receiver_id])
    if @friendship 
      @todo = Todo.create(user_id: @user.id, receiver_id: params[:receiver_id], content: params[:content], is_finish: false)
      render json: {id: @todo.id}
    else
      render json: {result_code: 'f', msg: '对方还不是你的好友。'}
    end
  end
  
  # post new_help_to_group 新建群请求
  # params: token, group_id, content
  def new_help_to_group
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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
      render json: {return_code: "bad token"}
      return
    end
    @user = User.find_by(openid: cache_openid)
    @friendship = Friendship.find_by(user_id: @user.id, friend_id: params[:friend_id])
    unless @friendship
      render json: {msg: '您没有这个朋友'}
      return
    end
    if @friendship.friend_id == @user.id
      @user.update(nickname: params[:nickname])
      render json: {result_code: 't'}
    elsif
      @friendship.update(nickname: params[:nickname])
      render json: {result_code: 't'}
    end
  end

  # post close_group_help 关闭群请求 
  # params: token, grouptodo_id
  def close_group_help
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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
      render json: {return_code: "bad token"}
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

  # post rehelp  重启请求
  # params token, todo_id
  def rehelp
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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
      render json: {return_code: "bad token"}
      return
    end
    @todo = Todo.find_by(id: params[:todo_id])
    @discussions = @todo.discussions
  end

  # post new_discussion  添加讨论
  # params token, todo_id, content
  def new_discussion
    # 检查 token 是否过期
    cache_openid = $redis.get(params[:token])
    unless cache_openid
      render json: {return_code: "bad token"}
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

