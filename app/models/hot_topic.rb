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

  # 推入待选队列
  def self.batch_push_into_wait_hot_topic_ids(topic_id)
    hot_7_topics.push_into_wait_list(topic_id)
    hot_1_topics.push_into_wait_list(topic_id)

    hot_7_topics.push_into_wait_list_item_of_slot_expire_time(topic_id)
    hot_1_topics.push_into_wait_list_item_of_slot_expire_time(topic_id)
  end

  # 增加分数
  def self.incr_score(topic_id, score)
    hot_7_topics.hot_topic_item_with_timeslot(hot_7_topics.beginning_of_timeslot, topic_id).incr(score)
    hot_1_topics.hot_topic_item_with_timeslot(hot_1_topics.beginning_of_timeslot, topic_id).incr(score)
  end

  # 每个time slot保存的待选id
  def wait_list_item(beginning_of_timeslot)
    Redis::Set.new(wait_list_item_key(beginning_of_timeslot),
                  expireat: timescope.since(beginning_of_timeslot))
  end

  # 每个热点在不同timeslot的分数
  def hot_topic_item_with_timeslot(beginning_of_timeslot, topic_id)
    Redis::Counter.new(hot_topic_item_with_timeslot_key(beginning_of_timeslot, topic_id),
                      expireat: timescope.since(beginning_of_timeslot))
  end

  # 热点列表存储的排序set SortedSet[topic_id] = topic_score
  # 过期时间越短 重算最高分会导致大量的redis数据读取
  # ，其实在这段时间内很有可能不会对topic产生影响
  # 将过期时间设为timescope的结束点，使用worker更新hot_topic_sorted_set
  def hot_topic_sorted_set
    Redis::SortedSet.new(hot_topic_key,
                        expireat: timescope.since(beginning_of_timeslot))
  end

  # 过期时间slot_expire_time内更新的id
  def wait_list_item_of_slot_expire_time(beginning_of_slot_expire_time)
    Redis::Set.new(slot_expire_time_wait_list_item_key(beginning_of_slot_expire_time),
                  expireat: (slot_expire_time * 2).since(beginning_of_slot_expire_time))
  end

  # 每个topic对应的score
  def hot_topic_item_score(topic_id)
    redis_value = Redis::Value.new(hot_topic_item_key(topic_id),
                                  expireat: slot_expire_time.since(beginning_of_slot_expire_time))
    return redis_value.value.to_i if redis_value.value.present?
    score = 0
    beginning_of_timeslot_list.each_with_index do |time, index|
      score += hot_topic_item_with_timeslot(time, topic_id).value * (index + 1)
    end
    redis_value.value = score
    score
  end

  # 待选队列里的topic_ids
  def wait_hot_topic_ids
    ids_set = Set.new
    beginning_of_timeslot_list.each do |time|
      ids_set.merge wait_list_item(time)
    end
    ids_set.to_a
  end

  # 推入待选队列
  #
  def push_into_wait_list(topic_id)
    wait_list_item(beginning_of_timeslot).add(topic_id)
  end

  # 推入在slot_expire_time时间内更新的topic,在worker中用它来改变hot_topic_sorted_set
  def push_into_wait_list_item_of_slot_expire_time(topic_id)
    wait_list_item_of_slot_expire_time(beginning_of_slot_expire_time).add(topic_id)
  end

  # 最热门的100条
  def max_num_members
    hot_topic_sorted_set.members.reverse[0..(MAX_NUM - 1)]
  end

  # 热门100条的最小分数
  def min_score
    hot_topic_sorted_set[max_num_members.last]
  end

  # 热点列表id
  def hot_topic_sorted_ids
    redis_sorted_set = hot_topic_sorted_set
    redis_sorted_set_members = max_num_members
    return redis_sorted_set_members if redis_sorted_set_members.present?

    wait_hot_topic_ids.each do |topic_id|
      redis_sorted_set[topic_id] = hot_topic_item_score(topic_id)
    end
    # 如果比最小分数小则删除
    redis_sorted_set.delete_if{|key| redis_sorted_set[key] < min_score}
    max_num_members
  end

  # 获取当前所处的slot_expire_time，作为标志热点列表的过期时间
  #
  def beginning_of_slot_expire_time(time = Time.now)
    raise "only suppurt timeslot <= 1.days of this method" if timeslot > 1.days
    hour = time.hour
    min = time.min
    offset_seconds = (hour * 60 * 60 + min * 60) / slot_expire_time * slot_expire_time
    offset_seconds.seconds.since time.beginning_of_day
  end

  # 获取当前所处的time slot，作为标志一个topic对应的某个时间点
  #
  def beginning_of_timeslot(time = Time.now)
    raise "only suppurt timeslot <= 1.days of this method" if timeslot > 1.days
    hour = time.hour
    min = time.min
    offset_seconds = (hour * 60 * 60 + min * 60) / timeslot * timeslot
    offset_seconds.seconds.since time.beginning_of_day
  end

  # 获取每个time slot开始时间的数组
  #
  def beginning_of_timeslot_list
    list = []
    beginning_of_timeslot = beginning_of_timeslot(Time.now)

    timeslot_num.times do |index|
      list.unshift (index * timeslot).ago(beginning_of_timeslot)
    end

    list
  end

  private
  # 等待队列各timeslot的key
  def wait_list_item_key(time)
    "#{wait_hot_topic_key}/wait_list/#{time.to_i}"
  end

  # 等待队列各slot_expire_time的key
  def slot_expire_time_wait_list_item_key(time)
    "#{wait_hot_topic_key}/slot_expire_time/#{time.to_i}"
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
  def hot_topic_item_with_timeslot_key(time, topic_id)
    "#{hot_topic_key}/hot_topics/#{topic_id}/timeslot/#{time.to_i}"
  end

  def hot_topic_prifix_key
    "HotTopic#{timescope}"
  end
end
