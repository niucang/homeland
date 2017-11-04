require 'rails_helper'

describe HotTopic, type: :model do
  before {
    # UpdateWaitTopicListWorker.new.perform
    @day_topic = HotTopic.hot_1_topics
  }
  describe 'worker' do
    it 'worker should run and update wait topic list' do
      # expect(@day_topic.wait_hot_topics.length).to eq(@day_topic.timeslot_num)
      #
      # @day_topic.wait_list_item(1) << 2
      # UpdateWaitTopicListWorker.new.perform
      # expect(@day_topic.wait_list_item(1).size).to eq(0)
      # expect(@day_topic.wait_list_item(0).size).to eq(1)
      #
    end
  end

  describe '.beginning_of_timeslot' do
    it 'should work' do
      now = Time.now
      last_timeslot_now = @day_topic.timeslot.ago now
      current_timeslot = @day_topic.beginning_of_timeslot now
      last_timeslot = @day_topic.beginning_of_timeslot last_timeslot_now
      expect((current_timeslot - last_timeslot).seconds).to eq(@day_topic.timeslot)
    end
  end

  describe '.push_into_wait_list' do
    it 'should push into wait list' do
      @day_topic.push_into_wait_list(999)

      expect(@day_topic.wait_hot_topic_ids.include? 999.to_s).to eq true
    end
  end

  describe '.hot_topic_item_score' do
    it 'should be work' do
      HotTopic.batch_push_into_wait_hot_topic_ids(999)
      HotTopic.incr_score(999, 3)
      HotTopic.incr_score(999, 1)
      HotTopic.incr_score(999, 1)

      expect(@day_topic.hot_topic_item_score(999)).to eq 5 * @day_topic.timeslot_num

      HotTopic.incr_score(999, 1)
      expect(@day_topic.hot_topic_item_score(999)).to eq 5 * @day_topic.timeslot_num
      expect(@day_topic.hot_topic_sorted_ids.include? "999").to eq true

      expect(@day_topic.hot_topic_sorted_set.ttl < @day_topic.slot_expire_time * 60).to eq true
    end
  end
end
