require 'omniauth-wechat-oauth2'
Rails.application.config.middleware.use OmniAuth::Builder do
  # provider :wechat, ENV["WECHAT_APP_ID"], ENV["WECHAT_APP_SECRET"]
  # provider :open_wechat, ENV["WECHAT_APP_ID"], ENV["WECHAT_APP_SECRET"]
end
