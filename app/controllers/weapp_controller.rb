class WeappController < ApplicationController

  # post login 登录系统，取出token
  # params js_code
  def login
    js_code = params[:js_code]
    if js_code == ''
      render plain: ''
      return
    end
    wx_user = WxPay::Service.authenticate_from_weapp(js_code)
    if wx_user["openid"] == ''
      render plain: ''
      return
    end
	@user = Thirdpartyid.find_by(openid: wx_user['openid'], scene: 0).user
    token = SecureRandom.uuid.tr('-', '')
    unless @user
      @user = User.create(nickname: Time.new.to_i.to_s)
	  Thirdpartyid.create(openid: wx_user['openid'], scene: 0, user_id: @user.id)
    end
    $redis.hset(token, openid, wx_user["openid"], userid, @user.id)  # 因为不想解密那些敏感信息，就不来存储会话密钥了。
    render json: {result_code: "t", token: token, current_user: {id: @user.id, nickname: @user.nickname}}
  end

    # post wechat_pay 微信支付
    # params token
  def wechat_pay
    # 检查 token 是否过期
    openid = $redis.hget(params[:token], openid)
    unless openid
      render json: {result_code: "bad token"}
      return
    end
    pay_params = {
      body: '真善美美容-服务费', 
      out_trade_no: Time.now.to_i,
      total_fee: params[:sum],
      spbill_create_ip: request.remote_ip(),
      notify_url: 'https://www.hopee.xyz/notify',
      trade_type: 'JSAPI', 
      openid: openid
    }
    uo_result = WxPay::Service.invoke_unifiedorder pay_params
    req_params = {
      prepayid: uo_result["prepay_id"],
      noncestr:  uo_result["nonce_str"]
    }
    r = WxPay::Service.generate_js_pay_req req_params
    render json: r
  end

  # post notify 接收微信支付通知
  # params request
  def notify
    result = Hash.from_xml(request.body.read)["xml"]
    if WxPay::Sign.verify?(result)
	  if result["result_code"] == "SUCCESS"
        unless Payment.find_by(transaction_id: result["transaction_id"])
	      user_id = Thirdpartyid.find_by(openid: result["openid"], scene: 0).user_id
	      remaining = Payment.where(user_id: user_id).last.remaining + result["total_fee"].to_i
          Payment.create(
	  	    user_id: user_id, 
		    openid: result["openid"], 
		    transaction_id: result["transaction_id"],
		    total_fee: result["total_fee"], 
		    remaining: remaining, result["time_end"]
		  )
		 end
      end
      render :xml => {result_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
    else
      render :xml => {result_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
    end
  end

end
