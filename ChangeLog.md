# 课业
### 一，需求分析
1. 一周或者24小时视为同一类型，称之`timescope`
2. 一天或者1小时视为分割断，称为`timeslot`
3. 每个`timeslot`的`topic`会对应一个没有时间加权的分数`score = V0 + P0 * 3`
4. 都有对应过期时间 `slot_expire_time`
5. 随着时间推移会有 `timeslot` 的加权
6. 对于处于当前`timeslot`的时间点会有过期时间`current_expire_time`
7. 限制数量 `SHOW_AMOUNT = 100`
8. 热门队列 `hot_topic_queue`


### 二，设计说明
1. 整体分为 待排序队列（timescope内的id）和 存分数的`SortedSet`两部分

2. 当前时间不在`timeslot`内则`timeslot`可保存时长： `timescope - timescope / timeslot`
3. `hot_topic_queue`的过期时间为`timeslot`, 保存需要展示的`SHOW_AMOUNT`条数据
4. 各放一个定时worker在`current_expire_time`后重新更新当前`current_expire_time`内更新的帖子
5. 若定时worker在当前`timescope`的最后一个`slot_expire_time`则更改保存时间为 `timescope - timescope / timeslot`
6. 每个timeslot失效的时候触发所有index左移.
