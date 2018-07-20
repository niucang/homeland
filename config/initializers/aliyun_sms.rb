require 'aliyun/sms'
Aliyun::Sms.configure do |config|
    config.access_key_secret = ENV['aliyun_sms_secret']
    config.access_key_id = ENV['aliyun_sms_key']
    config.action = 'SendSms'                       # default value
    config.format = 'JSON'                           # http return format, value is 'JSON' or 'XML'
    config.region_id = 'cn-hangzhou'                # default value
    config.sign_name = '普惠社区'                  
    config.signature_method = 'HMAC-SHA1'           # default value
    config.signature_version = '1.0'                # default value
    config.version = '2017-05-25'                   # default value
end
