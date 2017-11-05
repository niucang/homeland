require 'rails_helper'

describe HotTopic, type: :model do
  before {
    # UpdateWaitTopicListWorker.new.perform
    @day_topic = HotTopic.hot_1_topics
  }
  describe 'worker' do
    it 'UpdateHotTopicSortedSetWorker should run and update wait topic list' do
      HotTopic.batch_push_into_wait_hot_topic_ids(999)
      HotTopic.incr_score(999, 1)
      expect(@day_topic.hot_topic_item_score(999)).to eq 1 * @day_topic.timeslot_num
      expect(@day_topic.hot_topic_sorted_ids.include? "999").to eq true

      now = Time.now
      beginning_of_timeslot = @day_topic.beginning_of_timeslot(now)
      beginning_of_slot_expire_time = @day_topic.beginning_of_slot_expire_time(now)

      slot_expire_time_set = @day_topic.wait_list_item_of_slot_expire_time(@day_topic.slot_expire_time.since(beginning_of_slot_expire_time))

      @day_topic.hot_topic_item_with_timeslot(beginning_of_timeslot, 888).incr(888)
      slot_expire_time_set.add(888)
      expect(@day_topic.hot_topic_item_score(888)).to eq 888 * @day_topic.timeslot_num
      expect(@day_topic.hot_topic_sorted_ids.include? "888").to eq false
      UpdateHotTopicSortedSetWorker.new.perform(1)
      expect(@day_topic.hot_topic_sorted_ids.include? "888").to eq beginning_of_slot_expire_time.min != 0
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

      expect(@day_topic.hot_topic_sorted_set.ttl < @day_topic.timeslot * 60).to eq true
    end
  end
end
