require 'rails_helper'

describe HotTopic, type: :model do
  describe 'worker' do
    it 'worker should run and update wait topic list' do
      UpdateWaitTopicListWorker.new.perform
      day_topic = HotTopic.hot_1_topics
      expect(day_topic.wait_hot_topics.length).to eq(day_topic.timeslot_num)

      day_topic.wait_list_item(1) << 2
      UpdateWaitTopicListWorker.new.perform
      expect(day_topic.wait_list_item(1).size).to eq(0)
      expect(day_topic.wait_list_item(0).size).to eq(1)

    end
  end
end
