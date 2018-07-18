class MsgCodeService
  class << self
    def send_code_and_cache_sms(mobile_phone)
      cache_key = mobile_phone_cache_key(mobile_phone)
      sms_code = $redis.get(cache_key).presence || get_code
      $redis.set(cache_key, sms_code, 2 * 60 * 60)
      Aliyun::Sms.send(mobile_phone, template_code, {sms_code: sms_code}, _)
    end

    def verify_message_code(mobile_phone, sms_code)
      $redis.get(mobile_phone_cache_key(mobile_phone)).to_s == sms_code.to_s
    end

    private
      def mobile_phone_cache_key(mobile_phone)
        "sms_code_for_mobile_phone:#{mobile_phone}"
      end

      def get_code
        rand(0000...9999)
      end
  end
end
