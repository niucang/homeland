section_node_hash = {
  '社区小喇叭' => %w(办事指南 生活导航 物业服务),
  '房源租售' => %w(寻找小屋 房源售卖 房屋出租),
  '求职招聘' => %w(百姓求职 公司招聘),
  '餐饮娱乐' => %w(小镇休闲 美食小店 商务酒楼),
  '游山玩水' => %w(结伴出行 旅游社交),
  '商家中心' => %w(商场促销 海外代购 小镇店铺)
}
section_node_hash.each do |section_name, nodes|
  section = Section.create(name: section_name)
  nodes.each do |node_name|
    Node.create(name: node_name, summary: node_name, section_id: section.id)
  end
end
