class UpdateHotTopicSortedSetWorker < BaseWorker
  def perform(timescope)
    if timescope == 1
      hot_topic = HotTopic.hot_1_topics
    else
      hot_topic = HotTopic.hot_7_topics
    end

    now = Time.now
    beginning_of_timeslot = hot_topic.beginning_of_timeslot(now)
    beginning_of_slot_expire_time = hot_topic.beginning_of_slot_expire_time(now)

    if beginning_of_timeslot != beginning_of_slot_expire_time
      #上一个过期时间内更新的id
      last_wait_list_item_of_slot_expire_time_ids = hot_topic.wait_list_item_of_slot_expire_time(hot_topic.slot_expire_time.since(beginning_of_slot_expire_time)).value

      last_wait_list_item_of_slot_expire_time_ids.each do |topic_id|
        # 如果大于最低分则推入hot_topic_sorted_set
        if hot_topic.hot_topic_item_score(topic_id) > hot_topic.min_score
          hot_topic.hot_topic_sorted_set[topic_id] = hot_topic.hot_topic_item_score(topic_id)
        end
      end
    end
  end
end
