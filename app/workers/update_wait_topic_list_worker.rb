class UpdateWaitTopicListWorker < BaseWorker
  def perform
    hot_topic = HotTopic.hot_1_topics

    wait_hot_topics_list = hot_topic.wait_hot_topics_list
    # 初始化等待队列
    if wait_hot_topics_list.length == 0
      hot_topic.timeslot_num.times do |index|
        wait_hot_topics_list << hot_topic.wait_list_item(index).key
      end
    end

    # 整体往左移, 最右端塞入空list
    wait_hot_topics_list.value.each_with_index do |_, index|

      if index == hot_topic.timeslot_num - 1
        $redis.del hot_topic.wait_list_item(index).key
        next
      end

      hot_topic.wait_list_item(index + 1).value.each do |list_item|
        hot_topic.wait_list_item(index).add list_item
        hot_topic.wait_list_item(index + 1).pop
      end
    end

  end
end
