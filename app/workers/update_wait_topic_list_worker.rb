class UpdateWaitTopicListWorker < BaseWorker
  def perform
    hot_topic = HotTopic.hot_1_topics

    wait_hot_topics_list = hot_topic.wait_hot_topics_list
    # 初始化等待队列
    if wait_hot_topics_list.length == 0
      hot_topic.timeslot_num.times do |index|
        wait_hot_topics_list << wait_list_item(index)
      end
    end

    # 整体往左移, 最右端塞入空list
    wait_hot_topics_list.each do |index|
      wait_list_item(index).value = wait_list_item(index + 1).value
      wait_list_item(index).value = Redis::Set.new(wait_list_item_key(index),
                                                  expiration: hot_topic.timescope) if
                                                  index == hot_topic.timeslot_num - 1
    end

  end
end
