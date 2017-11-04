# 课业
### 一，需求分析
1. 一周或者24小时视为同一类型，称之`timescope`
2. 一天或者1小时视为分割断，称为`timeslot`
3. 每个`timeslot`的`topic`会对应一个没有时间加权的分数`score = V0 + P0 * 3`
4. 都有对应过期时间 `slot_expire_time`
5. 随着时间推移会有 `timeslot` 的加权
6. 对于处于当前`timeslot`的时间点会有过期时间`current_expire_time`
7. 限制数量 `SHOW_AMOUNT = 100`


### 二，设计说明
1. 整体分为 待排序队列`wait_hot_topic_ids` 和 存分数的`hot_topic_sorted_set`两部分

2. `wait_list_item` 存某个`timeslot`内对应的id，过期时间是整个 `timescope`，可由`push_into_wait_list`方法推入待排队列

3. `wait_hot_topic_ids`由`wait_list_item`组成

4. `hot_topic_sorted_set` 的过期时间是 `slot_expire_time（eg: 10min）`, 当存在时则返回，不存在则重新计算 `hot_topic_sorted_set`

5. `hot_topic_sorted_set`的计算目前是遍历所有待排队列`wait_hot_topic_ids`的id, 将由`hot_topic_item_score`获取分数存在`hot_topic_sorted_set`中

6. `hot_topic_item_score` 则是通过遍历某个id对应的所有timeslot 的加权总分

7. 每个id在每个`timeslot`的分数存在 `hot_topic_item_with_timeslot` 中，过期时间是整个`timescope`

8. 通过`beginning_of_timeslot`获取所给的参数`time`获取对应所处的`timeslot`的开始时间，用于区分每个`timeslot`
