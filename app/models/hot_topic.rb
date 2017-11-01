class HotTopic

  include Redis::Objects
  attr_reader :timescope, :timeslot,
              :slot_expire_time, :wait_hot_topics_list

  def initialize(timescope, timeslot, slot_expire_time)
    @timescope = timescope
    @timeslot = timeslot
    @slot_expire_time = slot_expire_time
    @timeslot_num = @timescope / @timeslot
    @wait_hot_topics_list = Redis::List.new("HotTopic:#{@timescope}", marshal: true, maxlength: @timeslot_num)
  end

  # 待选队列
  def wait_hot_topics
    wait_hot_topics_list.values
  end

  # 待选队列里的topic_ids
  def wait_hot_topic_ids
    ids_set = Set.new
    wait_hot_topics.each do |list|
      ids_set.merge list
    end
    ids_set.to_a
  end

  # 推入待选队列
  def push_into_wait_list(topic_id)
    wait_hot_topics_list.redis.watch wait_hot_topics_list.key

    new_last_timeslot = current_timeslot.add(topic_id)

    wait_hot_topics_list.redis.multi
    wait_hot_topics_list.pop
    wait_hot_topics_list << new_last_timeslot

    if wait_hot_topics_list.redis.exec.nil?
      push_into_wait_list(topic_id)
    else
      return wait_hot_topics
    end
  rescue
    wait_hot_topics
  end

  def current_timeslot
    wait_hot_topics_list.last
  end
end
