class HotTopic

  MAX_NUM = 100

  include Redis::Objects
  attr_reader :timescope, :timeslot,
              :slot_expire_time,
              :timeslot_num

  def initialize(timescope, timeslot, slot_expire_time)
    @timescope = timescope
    @timeslot = timeslot
    @slot_expire_time = slot_expire_time
    @timeslot_num = @timescope / @timeslot
  end

  def self.hot_7_topics
    new(7.days, 1.days, 1.hours)
  end

  def self.hot_1_topics
    new(1.days, 1.hours, 10.minutes)
  end

  def self.batch_push_into_wait_hot_topic_ids(topic_id)
    hot_7_topics.push_into_wait_list(topic_id)
    hot_1_topics.push_into_wait_list(topic_id)
  end

  def self.incr_score(topic_id, score)
    hot_7_topics.hot_topic_item_with_timeslot(current_timeslot_index, topic_id).incr(score)
    hot_1_topics.hot_topic_item_with_timeslot(current_timeslot_index, topic_id).incr(score)
  end

  # 待选队列redis::list
  def wait_hot_topics_list
    Redis::List.new(wait_hot_topic_key, maxlength: timeslot_num)
  end

  # 待选队列
  # 待选队列包含每个timeslot的key
  # ["key1", "key2"] "key"为一个set对应的key
  def wait_hot_topics
    wait_hot_topics_list.value
  end

  # 待选队列里的topic_ids
  def wait_hot_topic_ids
    ids_set = Set.new
    wait_hot_topics.each_with_index do |index, _|
      ids_set.merge wait_list_item(index)
    end
    ids_set.to_a
  end

  # 推入待选队列
  #
  def push_into_wait_list(topic_id)
    wait_list_item(wait_hot_topics_list.length - 1).add(topic_id)
  end

  def wait_list_item(index)
    Redis::Set.new(wait_list_item_key(index), expiration: timescope) if
     index < timeslot_num
  end

  # 每个热点在不同timeslot的Counter
  def hot_topic_item_with_timeslot(index, topic_id)
    expire_time = index == current_timeslot_index ? slot_expire_time : timescope
    Redis::Counter.new(hot_topic_item_with_timeslot_key(index, topic_id), expiration: expire_time)
  end

  # 每个topic对应的score
  def hot_topic_item_score(topic_id)
    redis_value = Redis::Value.new(hot_topic_item_key(topic_id), expiration: slot_expire_time)
    return redis_value if redis_value.value.present?

    wait_hot_topics_length = current_timeslot_index

    score = 0
    wait_hot_topics_length.downto(0).each do |index|
      score += hot_topic_item_with_timeslot(index, topic_id).value * (index + 1)
    end
    redis_value.value = score
    score
  end

  # 热点列表存储set
  def hot_topic_sorted_set
    Redis::SortedSet.new(hot_topic_key, expiration: timeslot)
  end

  # 最大分
  def max_num_members
    hot_topic_sorted_set.members.reverse[0..(MAX_NUM - 1)]
  end

  # 热点列表id
  def hot_topic_sorted_ids
    redis_sorted_set = hot_topic_sorted_set
    redis_sorted_set_members = max_num_members
    return redis_sorted_set_members if redis_sorted_set_members.present?

    wait_hot_topics_length = current_timeslot_index

    wait_hot_topic_ids.each do |topic_id|
      redis_sorted_set[topic_id] = hot_topic_item_score(topic_id)
    end
    # 如果比最小分数小则删除
    redis_sorted_set.delete_if{|key| redis_sorted_set[key] < redis_sorted_set[max_num_members.last]}
    max_num_members
  end

  # 目前所处timeslot的index
  def current_timeslot_index
    wait_hot_topics.length - 1
  end

  private
  # 等待队列各timeslot的key
  def wait_list_item_key(index)
    "#{wait_hot_topic_key}/wait_list/#{index}"
  end

  # 等待队列的key
  def wait_hot_topic_key
    "#{hot_topic_prifix_key}::Wait"
  end

  # hot topics队列的key
  def hot_topic_key
    "#{hot_topic_prifix_key}::Hot"
  end

  # 每个 topic 分数的key, 过期时间为slot_expire_time
  def hot_topic_item_key(topic_id)
    "#{hot_topic_key}/hot_topics/#{topic_id}"
  end

  # 每个 topic 没有时间加权的分数在某个timeslot的key，过期时间为 timescope 最近一条为slot_expire_time
  def hot_topic_item_with_timeslot_key(index, topic_id)
    "#{hot_topic_key}/hot_topics/#{topic_id}/timeslot/#{index}"
  end

  def hot_topic_prifix_key
    "HotTopic#{timescope}"
  end
end
