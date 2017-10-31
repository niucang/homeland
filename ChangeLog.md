# 课业
### 一，需求分析
1. 一周或者24小时视为同一类型，称之`timescope`
2. 一天或者1小时视为分割断，称为`timeslot`
3. 展示对象，timescope 内create 或者 update的对象
4. 每个`timeslot`的`topic`会对应一个没有时间加权的分数`score = V0 + P0 * 3`
5. 都有对应过期时间 `slot_expire_time`
6. 随着时间推移会有 `timeslot` 的加权
7. 对于处于当前`timeslot`的时间点会有过期时间`current_expire_time`
8. 限制数量 `SHOW_AMOUNT = 100`
9. 热门队列 `hot_topic_queue`
10. 待选热门队列 `wait_hot_topic`


### 二，设计说明
1. 当前时间不在`timeslot`内则`timeslot`可缓存时长： `timescope - timescope / timeslot`
2. `hot_topic_queue`的过期时间为`timeslot`, 缓存需要展示的`SHOW_AMOUNT`条数据，设置一个最低分作为触发缓存失效的 开关
3. 各放一个定时job在`current_expire_time`后重新更新当前`current_expire_time`内更新的帖子，看是否满足触发`SHOW_AMOUNT`失效的开关，`hot_topic_queue`失效则放入`hot_topic_queue`大于最低分的`topic`, 若队列数量大于`SHOW_AMOUNT`则排除小于最低分的`topic`, 更新触发开关
4. 若定时job在当前`timescope`的最后一个`timeslot`则更改缓存时间为 `timescope - timescope / timeslot`

5. 使用Redis保存一个可能要展现的topic_id队列,每个`timeslot`开始时就塞入一个数组并放入topic id, 数组个数大于数量为 `（timescope／timeslot）`则将头部的数组放弃掉
