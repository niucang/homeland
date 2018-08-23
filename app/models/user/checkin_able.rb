class User
  module CheckinAble
    extend ActiveSupport::Concern
    included do
      has_many :check_in_records
    end

    def check_in_today?
      today_checkin.exists?
    end

    def today_checkin
      check_in_records.where(created_at: Time.now.beginning_of_day...Time.now.end_of_day)
    end

    def yesterday_checkin
      yesterday = Time.now.yesterday
      check_in_records.where(created_at: yesterday.beginning_of_day...yesterday.end_of_day).first
    end

    def check_in!
      raise 'Check out Error' if check_in_today?
      yesterday = Time.now.yesterday
      yesterday_checkin = yesterday_checkin
      if yesterday_checkin.blank?
        today_continuous_day = 1
      else
        today_continuous_day = yesterday_checkin.coutinuous_days + 1
      end
      check_in_records.create!(coutinuous_days: today_continuous_day)
    end

    def coutinuous_days
      if check_in_today?
        today_checkin.first.coutinuous_days
      else
        yesterday_checkin&.coutinuous_days || 0
      end
    end
  end
end
