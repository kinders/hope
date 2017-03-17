# required
WxPay.appid = 'YOUR_APPID'  # 应用编号
WxPay.key = 'YOUR_KEY'      # 应用的键
WxPay.mch_id = 'YOUR_MCH_ID' # 商户编号
WxPay.debug_mode = true # default is `true` 调试模式

# cert, see https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3
# 证书
# using PCKS12
# 使用 PCKS12 数字证书
# WxPay.set_apiclient_by_pkcs12(File.read(pkcs12_filepath), pass)

# if you want to use `generate_authorize_req` and `authenticate`
# 如果想使用`生成授权请求`和`认证`：
WxPay.appsecret = 'YOUR_SECRET'    # 应用密码

# optional - configurations for RestClient timeout, etc.
# 选项 —— 配置 RestClient 的超时，等。
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}

