// Account data models and static data

// 我的
class MineItem {
  final String name;
  final String icon;

  const MineItem({required this.name, required this.icon});
}

// 徽章
class BadgeItem {
  final String name;
  final String icon;
  final String iconS;

  const BadgeItem({
    required this.name,
    required this.icon,
    required this.iconS,
  });
}

// 更新
class UpdateItem {
  final int key;
  final String name;
  final String detail;
  final String icon;

  const UpdateItem({
    required this.key,
    required this.name,
    required this.detail,
    required this.icon,
  });
}

// 分享
class ShareItem {
  final int key;
  final String name;
  final String icon;

  const ShareItem({required this.key, required this.name, required this.icon});
}

// 发现
class DiscoverItem {
  final int key;
  final String name;
  final String icon;

  const DiscoverItem({
    required this.key,
    required this.name,
    required this.icon,
  });
}

// 类别
class CategoryItem {
  final int id;
  final String name;
  final int inEx;
  final bool isDefault;
  final int icon;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.inEx,
    required this.isDefault,
    required this.icon,
  });
}

// 添加类别
class AddCategoryItem {
  final String id;
  final String name;
  final List<int> icon;

  const AddCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}

// 图标数据 (renamed from IconData to avoid conflict with Flutter's IconData)
class CategoryIcon {
  final int id;
  final String icon;
  final String iconL;
  final String iconS;

  const CategoryIcon({
    required this.id,
    required this.icon,
    required this.iconL,
    required this.iconS,
  });
}

// ==================== Data ====================

// 我的
const List<List<MineItem>> mineJson = [
  [MineItem(name: '徽章', icon: 'assets/images/mine_badge.png')],
  [
    MineItem(name: '类别设置', icon: 'assets/images/mine_tallytype.png'),
    MineItem(name: '定时提醒', icon: 'assets/images/mine_remind.png'),
    MineItem(name: '声音开关', icon: 'assets/images/mine_sound.png'),
    MineItem(name: '明细详情', icon: 'assets/images/mine_detail.png'),
  ],
  [
    MineItem(name: '升级至专业版', icon: 'assets/images/mine_upgrade.png'),
    MineItem(name: '推荐鲨鱼记账给好友', icon: 'assets/images/mine_share.png'),
    MineItem(name: '去App Store给鲨鱼记账评分', icon: 'assets/images/mine_rating.png'),
    MineItem(name: '意见反馈', icon: 'assets/images/mine_feedback.png'),
    MineItem(name: '帮助', icon: 'assets/images/mine_help.png'),
    MineItem(name: '关于鲨鱼记账', icon: 'assets/images/mine_about.png'),
  ],
];

// 徽章
const List<List<BadgeItem>> badgeJson = [
  [
    BadgeItem(
      name: '新手入门',
      icon: 'assets/images/1.png',
      iconS: 'assets/images/1_s.png',
    ),
    BadgeItem(
      name: '连续3天徽章',
      icon: 'assets/images/2.png',
      iconS: 'assets/images/2_s.png',
    ),
    BadgeItem(
      name: '连续7天徽章',
      icon: 'assets/images/3.png',
      iconS: 'assets/images/3_s.png',
    ),
    BadgeItem(
      name: '连续21天徽章',
      icon: 'assets/images/4.png',
      iconS: 'assets/images/4_s.png',
    ),
    BadgeItem(
      name: '连续50天徽章',
      icon: 'assets/images/5.png',
      iconS: 'assets/images/5_s.png',
    ),
    BadgeItem(
      name: '连续100天徽章',
      icon: 'assets/images/6.png',
      iconS: 'assets/images/6_s.png',
    ),
    BadgeItem(
      name: '连续200天徽章',
      icon: 'assets/images/7.png',
      iconS: 'assets/images/7_s.png',
    ),
    BadgeItem(
      name: '连续365天徽章',
      icon: 'assets/images/8.png',
      iconS: 'assets/images/8_s.png',
    ),
    BadgeItem(
      name: '连续500天徽章',
      icon: 'assets/images/9.png',
      iconS: 'assets/images/9_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '累计记账30天',
      icon: 'assets/images/10.png',
      iconS: 'assets/images/10_s.png',
    ),
    BadgeItem(
      name: '累计记账100天',
      icon: 'assets/images/11.png',
      iconS: 'assets/images/11_s.png',
    ),
    BadgeItem(
      name: '累计记账365天',
      icon: 'assets/images/12.png',
      iconS: 'assets/images/12_s.png',
    ),
    BadgeItem(
      name: '累计记账500天',
      icon: 'assets/images/13.png',
      iconS: 'assets/images/13_s.png',
    ),
    BadgeItem(
      name: '累计记账800天',
      icon: 'assets/images/14.png',
      iconS: 'assets/images/14_s.png',
    ),
    BadgeItem(
      name: '累计记账1000天',
      icon: 'assets/images/15.png',
      iconS: 'assets/images/15_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '累计记账99笔',
      icon: 'assets/images/16.png',
      iconS: 'assets/images/16_s.png',
    ),
    BadgeItem(
      name: '累计记账333笔',
      icon: 'assets/images/17.png',
      iconS: 'assets/images/17_s.png',
    ),
    BadgeItem(
      name: '累计记账555笔',
      icon: 'assets/images/18.png',
      iconS: 'assets/images/18_s.png',
    ),
    BadgeItem(
      name: '累计记账888笔',
      icon: 'assets/images/19.png',
      iconS: 'assets/images/19_s.png',
    ),
    BadgeItem(
      name: '累计记账1024笔',
      icon: 'assets/images/20.png',
      iconS: 'assets/images/20_s.png',
    ),
    BadgeItem(
      name: '累计记账2046笔',
      icon: 'assets/images/21.png',
      iconS: 'assets/images/21_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '馋虫',
      icon: 'assets/images/22.png',
      iconS: 'assets/images/22_s.png',
    ),
    BadgeItem(
      name: '吃货',
      icon: 'assets/images/23.png',
      iconS: 'assets/images/23_s.png',
    ),
    BadgeItem(
      name: '贪吃鬼',
      icon: 'assets/images/24.png',
      iconS: 'assets/images/24_s.png',
    ),
    BadgeItem(
      name: '吃霸',
      icon: 'assets/images/25.png',
      iconS: 'assets/images/25_s.png',
    ),
    BadgeItem(
      name: '饕鬄',
      icon: 'assets/images/26.png',
      iconS: 'assets/images/26_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '萌芽',
      icon: 'assets/images/27.png',
      iconS: 'assets/images/27_s.png',
    ),
    BadgeItem(
      name: '买买买',
      icon: 'assets/images/28.png',
      iconS: 'assets/images/28_s.png',
    ),
    BadgeItem(
      name: '购物狂',
      icon: 'assets/images/29.png',
      iconS: 'assets/images/29_s.png',
    ),
    BadgeItem(
      name: '剁手党',
      icon: 'assets/images/30.png',
      iconS: 'assets/images/30_s.png',
    ),
    BadgeItem(
      name: '维多利亚',
      icon: 'assets/images/31.png',
      iconS: 'assets/images/31_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '宅人漫步',
      icon: 'assets/images/32.png',
      iconS: 'assets/images/32_s.png',
    ),
    BadgeItem(
      name: '惬意闲人',
      icon: 'assets/images/33.png',
      iconS: 'assets/images/33_s.png',
    ),
    BadgeItem(
      name: '玩乐高手',
      icon: 'assets/images/34.png',
      iconS: 'assets/images/34_s.png',
    ),
    BadgeItem(
      name: '环游世界',
      icon: 'assets/images/35.png',
      iconS: 'assets/images/35_s.png',
    ),
    BadgeItem(
      name: '游戏人间',
      icon: 'assets/images/36.png',
      iconS: 'assets/images/36_s.png',
    ),
  ],
  [
    BadgeItem(
      name: '搬砖的',
      icon: 'assets/images/37.png',
      iconS: 'assets/images/37_s.png',
    ),
    BadgeItem(
      name: '卖瓜的',
      icon: 'assets/images/38.png',
      iconS: 'assets/images/38_s.png',
    ),
    BadgeItem(
      name: '小地主',
      icon: 'assets/images/39.png',
      iconS: 'assets/images/39_s.png',
    ),
    BadgeItem(
      name: '小老板',
      icon: 'assets/images/40.png',
      iconS: 'assets/images/40_s.png',
    ),
    BadgeItem(
      name: '土豪爸爸',
      icon: 'assets/images/41.png',
      iconS: 'assets/images/41_s.png',
    ),
  ],
];

// 更新
const List<UpdateItem> updateJson = [
  UpdateItem(
    key: 0,
    name: '去除广告',
    detail: '轻松去除广告',
    icon: 'assets/images/upgrade_noad.png',
  ),
  UpdateItem(
    key: 1,
    name: '饼图分析',
    detail: '记账数据更加一目了然',
    icon: 'assets/images/upgrade_chart.png',
  ),
  UpdateItem(
    key: 2,
    name: '解锁密码',
    detail: '保护隐私, 用起来更安全',
    icon: 'assets/images/upgrade_pwd.png',
  ),
  UpdateItem(
    key: 3,
    name: '预算管理',
    detail: '再也不用担心每个月超支了',
    icon: 'assets/images/upgrade_budget.png',
  ),
  UpdateItem(
    key: 4,
    name: '记账日历',
    detail: '查看, 补记更加方便',
    icon: 'assets/images/upgrade_calendar.png',
  ),
  UpdateItem(
    key: 5,
    name: '更多功能',
    detail: '更多强大的功能等你发现',
    icon: 'assets/images/upgrade_more.png',
  ),
];

// 分享
const List<ShareItem> shareJson = [
  ShareItem(key: 0, name: '微信', icon: 'assets/images/share_wx.png'),
  ShareItem(key: 1, name: '微信朋友圈', icon: 'assets/images/share_wxfc.png'),
  ShareItem(key: 2, name: 'QQ', icon: 'assets/images/share_qq.png'),
  ShareItem(key: 3, name: 'QQ空间', icon: 'assets/images/share_qqzone.png'),
  ShareItem(key: 4, name: '新浪微博', icon: 'assets/images/share_sina.png'),
  ShareItem(key: 5, name: '短信', icon: 'assets/images/share_sms.png'),
];

// 炫耀分享
const List<ShareItem> flauntJson = [
  ShareItem(key: 0, name: '保存图片', icon: 'assets/images/share_download.png'),
  ShareItem(key: 1, name: '微信', icon: 'assets/images/share_wx.png'),
  ShareItem(key: 2, name: '朋友圈', icon: 'assets/images/share_wxfc.png'),
  ShareItem(key: 3, name: 'QQ', icon: 'assets/images/share_qq.png'),
  ShareItem(key: 4, name: '新浪微博', icon: 'assets/images/share_sina.png'),
  ShareItem(key: 5, name: '短信', icon: 'assets/images/share_sms.png'),
];

// 发现
const List<DiscoverItem> discoverJson = [
  DiscoverItem(key: 0, name: '二手交易', icon: 'assets/images/i_finance_l.png'),
  DiscoverItem(key: 1, name: '二手车', icon: 'assets/images/e_car_l.png'),
  DiscoverItem(key: 2, name: '宠物', icon: 'assets/images/e_pet_l.png'),
  DiscoverItem(key: 3, name: '家政', icon: 'assets/images/e_house_l.png'),
];

// 类别
const List<CategoryItem> categoryJson = [
  // 支出
  CategoryItem(id: 0, name: '餐饮', inEx: 0, isDefault: true, icon: 0),
  CategoryItem(id: 1, name: '购物', inEx: 0, isDefault: true, icon: 1),
  CategoryItem(id: 2, name: '日用', inEx: 0, isDefault: true, icon: 2),
  CategoryItem(id: 3, name: '交通', inEx: 0, isDefault: true, icon: 3),
  CategoryItem(id: 4, name: '蔬菜', inEx: 0, isDefault: true, icon: 4),
  CategoryItem(id: 5, name: '水果', inEx: 0, isDefault: true, icon: 5),
  CategoryItem(id: 6, name: '零食', inEx: 0, isDefault: true, icon: 6),
  CategoryItem(id: 7, name: '运动', inEx: 0, isDefault: true, icon: 7),
  CategoryItem(id: 8, name: '娱乐', inEx: 0, isDefault: true, icon: 8),
  CategoryItem(id: 9, name: '通讯', inEx: 0, isDefault: true, icon: 9),
  CategoryItem(id: 10, name: '服饰', inEx: 0, isDefault: true, icon: 10),
  CategoryItem(id: 11, name: '美容', inEx: 0, isDefault: true, icon: 11),
  CategoryItem(id: 12, name: '住房', inEx: 0, isDefault: true, icon: 12),
  CategoryItem(id: 13, name: '居家', inEx: 0, isDefault: true, icon: 13),
  CategoryItem(id: 14, name: '孩子', inEx: 0, isDefault: true, icon: 14),
  CategoryItem(id: 15, name: '长辈', inEx: 0, isDefault: true, icon: 15),
  CategoryItem(id: 16, name: '社交', inEx: 0, isDefault: true, icon: 16),
  CategoryItem(id: 17, name: '旅行', inEx: 0, isDefault: true, icon: 17),
  CategoryItem(id: 18, name: '烟酒', inEx: 0, isDefault: true, icon: 18),
  CategoryItem(id: 19, name: '数码', inEx: 0, isDefault: true, icon: 19),
  CategoryItem(id: 20, name: '汽车', inEx: 0, isDefault: true, icon: 20),
  CategoryItem(id: 21, name: '医疗', inEx: 0, isDefault: true, icon: 21),
  CategoryItem(id: 22, name: '书籍', inEx: 0, isDefault: true, icon: 22),
  CategoryItem(id: 23, name: '学习', inEx: 0, isDefault: true, icon: 23),
  CategoryItem(id: 24, name: '宠物', inEx: 0, isDefault: true, icon: 24),
  CategoryItem(id: 25, name: '礼金', inEx: 0, isDefault: true, icon: 25),
  CategoryItem(id: 26, name: '礼物', inEx: 0, isDefault: true, icon: 26),
  CategoryItem(id: 27, name: '办公', inEx: 0, isDefault: true, icon: 27),
  CategoryItem(id: 28, name: '维修', inEx: 0, isDefault: true, icon: 28),
  CategoryItem(id: 29, name: '捐赠', inEx: 0, isDefault: true, icon: 29),
  CategoryItem(id: 30, name: '彩票', inEx: 0, isDefault: true, icon: 30),
  CategoryItem(id: 31, name: '亲友', inEx: 0, isDefault: true, icon: 31),
  CategoryItem(id: 32, name: '快递', inEx: 0, isDefault: true, icon: 32),
  // 收入
  CategoryItem(id: 33, name: '工资', inEx: 1, isDefault: true, icon: 33),
  CategoryItem(id: 34, name: '兼职', inEx: 1, isDefault: true, icon: 34),
  CategoryItem(id: 35, name: '理财', inEx: 1, isDefault: true, icon: 35),
  CategoryItem(id: 36, name: '礼金', inEx: 1, isDefault: true, icon: 36),
  CategoryItem(id: 37, name: '其他', inEx: 1, isDefault: true, icon: 37),
];

// 添加类别
const List<AddCategoryItem> addCategoryJson = [
  AddCategoryItem(
    id: '0',
    name: '娱乐',
    icon: [
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
    ],
  ),
  AddCategoryItem(
    id: '1',
    name: '饮食',
    icon: [
      57,
      58,
      59,
      60,
      61,
      62,
      63,
      64,
      65,
      66,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
    ],
  ),
  AddCategoryItem(
    id: '2',
    name: '医疗',
    icon: [77, 78, 79, 80, 81, 82, 83, 84, 85, 86],
  ),
  AddCategoryItem(
    id: '3',
    name: '学习',
    icon: [87, 88, 89, 90, 91, 92, 93, 94, 95, 96],
  ),
  AddCategoryItem(
    id: '4',
    name: '交通',
    icon: [
      97,
      98,
      99,
      100,
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      110,
      111,
    ],
  ),
  AddCategoryItem(
    id: '5',
    name: '购物',
    icon: [
      112,
      113,
      114,
      115,
      116,
      117,
      118,
      119,
      120,
      121,
      122,
      123,
      124,
      125,
      126,
      127,
      128,
      129,
      130,
      131,
      132,
      133,
      134,
      135,
      136,
      137,
      138,
      139,
    ],
  ),
  AddCategoryItem(
    id: '6',
    name: '生活',
    icon: [140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151],
  ),
  AddCategoryItem(
    id: '7',
    name: '个人',
    icon: [152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162],
  ),
  AddCategoryItem(
    id: '8',
    name: '家居',
    icon: [
      163,
      164,
      165,
      166,
      167,
      168,
      169,
      170,
      171,
      172,
      173,
      174,
      175,
      176,
      177,
    ],
  ),
  AddCategoryItem(
    id: '9',
    name: '家庭',
    icon: [178, 179, 180, 181, 182, 183, 184, 185, 186, 187],
  ),
  AddCategoryItem(
    id: '10',
    name: '健身',
    icon: [188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199],
  ),
  AddCategoryItem(
    id: '11',
    name: '办公',
    icon: [200, 201, 202, 203, 204, 205, 206, 207, 208],
  ),
  AddCategoryItem(
    id: '12',
    name: '收入',
    icon: [209, 210, 211, 212, 213, 214, 215, 216, 217, 218],
  ),
  AddCategoryItem(
    id: '13',
    name: '其他',
    icon: [219, 220, 221, 222, 223, 224, 225],
  ),
];

// 图标对应
const List<CategoryIcon> iconJson = [
  // 默认 (0-37)
  CategoryIcon(
    id: 0,
    icon: 'assets/images/e_catering.png',
    iconL: 'assets/images/e_catering_l.png',
    iconS: 'assets/images/e_catering_s.png',
  ),
  CategoryIcon(
    id: 1,
    icon: 'assets/images/e_shopping.png',
    iconL: 'assets/images/e_shopping_l.png',
    iconS: 'assets/images/e_shopping_s.png',
  ),
  CategoryIcon(
    id: 2,
    icon: 'assets/images/e_commodity.png',
    iconL: 'assets/images/e_commodity_l.png',
    iconS: 'assets/images/e_commodity_s.png',
  ),
  CategoryIcon(
    id: 3,
    icon: 'assets/images/e_traffic.png',
    iconL: 'assets/images/e_traffic_l.png',
    iconS: 'assets/images/e_traffic_s.png',
  ),
  CategoryIcon(
    id: 4,
    icon: 'assets/images/e_vegetable.png',
    iconL: 'assets/images/e_vegetable_l.png',
    iconS: 'assets/images/e_vegetable_s.png',
  ),
  CategoryIcon(
    id: 5,
    icon: 'assets/images/e_fruite.png',
    iconL: 'assets/images/e_fruite_l.png',
    iconS: 'assets/images/e_fruite_s.png',
  ),
  CategoryIcon(
    id: 6,
    icon: 'assets/images/e_snack.png',
    iconL: 'assets/images/e_snack_l.png',
    iconS: 'assets/images/e_snack_s.png',
  ),
  CategoryIcon(
    id: 7,
    icon: 'assets/images/e_sport.png',
    iconL: 'assets/images/e_sport_l.png',
    iconS: 'assets/images/e_sport_s.png',
  ),
  CategoryIcon(
    id: 8,
    icon: 'assets/images/e_entertainmente.png',
    iconL: 'assets/images/e_entertainmente_l.png',
    iconS: 'assets/images/e_entertainmente_s.png',
  ),
  CategoryIcon(
    id: 9,
    icon: 'assets/images/e_communicate.png',
    iconL: 'assets/images/e_communicate_l.png',
    iconS: 'assets/images/e_communicate_s.png',
  ),
  CategoryIcon(
    id: 10,
    icon: 'assets/images/e_dress.png',
    iconL: 'assets/images/e_dress_l.png',
    iconS: 'assets/images/e_dress_s.png',
  ),
  CategoryIcon(
    id: 11,
    icon: 'assets/images/e_beauty.png',
    iconL: 'assets/images/e_beauty_l.png',
    iconS: 'assets/images/e_beauty_s.png',
  ),
  CategoryIcon(
    id: 12,
    icon: 'assets/images/e_house.png',
    iconL: 'assets/images/e_house_l.png',
    iconS: 'assets/images/e_house_s.png',
  ),
  CategoryIcon(
    id: 13,
    icon: 'assets/images/e_home.png',
    iconL: 'assets/images/e_home_l.png',
    iconS: 'assets/images/e_home_s.png',
  ),
  CategoryIcon(
    id: 14,
    icon: 'assets/images/e_child.png',
    iconL: 'assets/images/e_child_l.png',
    iconS: 'assets/images/e_child_s.png',
  ),
  CategoryIcon(
    id: 15,
    icon: 'assets/images/e_elder.png',
    iconL: 'assets/images/e_elder_l.png',
    iconS: 'assets/images/e_elder_s.png',
  ),
  CategoryIcon(
    id: 16,
    icon: 'assets/images/e_social.png',
    iconL: 'assets/images/e_social_l.png',
    iconS: 'assets/images/e_social_s.png',
  ),
  CategoryIcon(
    id: 17,
    icon: 'assets/images/e_travel.png',
    iconL: 'assets/images/e_travel_l.png',
    iconS: 'assets/images/e_travel_s.png',
  ),
  CategoryIcon(
    id: 18,
    icon: 'assets/images/e_smoke.png',
    iconL: 'assets/images/e_smoke_l.png',
    iconS: 'assets/images/e_smoke_s.png',
  ),
  CategoryIcon(
    id: 19,
    icon: 'assets/images/e_digital.png',
    iconL: 'assets/images/e_digital_l.png',
    iconS: 'assets/images/e_digital_s.png',
  ),
  CategoryIcon(
    id: 20,
    icon: 'assets/images/e_car.png',
    iconL: 'assets/images/e_car_l.png',
    iconS: 'assets/images/e_car_s.png',
  ),
  CategoryIcon(
    id: 21,
    icon: 'assets/images/e_medical.png',
    iconL: 'assets/images/e_medical_l.png',
    iconS: 'assets/images/e_medical_s.png',
  ),
  CategoryIcon(
    id: 22,
    icon: 'assets/images/e_books.png',
    iconL: 'assets/images/e_books_l.png',
    iconS: 'assets/images/e_books_s.png',
  ),
  CategoryIcon(
    id: 23,
    icon: 'assets/images/e_study.png',
    iconL: 'assets/images/e_study_l.png',
    iconS: 'assets/images/e_study_s.png',
  ),
  CategoryIcon(
    id: 24,
    icon: 'assets/images/e_pet.png',
    iconL: 'assets/images/e_pet_l.png',
    iconS: 'assets/images/e_pet_s.png',
  ),
  CategoryIcon(
    id: 25,
    icon: 'assets/images/e_money.png',
    iconL: 'assets/images/e_money_l.png',
    iconS: 'assets/images/e_money_s.png',
  ),
  CategoryIcon(
    id: 26,
    icon: 'assets/images/e_gift.png',
    iconL: 'assets/images/e_gift_l.png',
    iconS: 'assets/images/e_gift_s.png',
  ),
  CategoryIcon(
    id: 27,
    icon: 'assets/images/e_office.png',
    iconL: 'assets/images/e_office_l.png',
    iconS: 'assets/images/e_office_s.png',
  ),
  CategoryIcon(
    id: 28,
    icon: 'assets/images/e_repair.png',
    iconL: 'assets/images/e_repair_l.png',
    iconS: 'assets/images/e_repair_s.png',
  ),
  CategoryIcon(
    id: 29,
    icon: 'assets/images/e_donate.png',
    iconL: 'assets/images/e_donate_l.png',
    iconS: 'assets/images/e_donate_s.png',
  ),
  CategoryIcon(
    id: 30,
    icon: 'assets/images/e_lottery.png',
    iconL: 'assets/images/e_lottery_l.png',
    iconS: 'assets/images/e_lottery_s.png',
  ),
  CategoryIcon(
    id: 31,
    icon: 'assets/images/e_friend.png',
    iconL: 'assets/images/e_friend_l.png',
    iconS: 'assets/images/e_friend_s.png',
  ),
  CategoryIcon(
    id: 32,
    icon: 'assets/images/e_express.png',
    iconL: 'assets/images/e_express_l.png',
    iconS: 'assets/images/e_express_s.png',
  ),
  CategoryIcon(
    id: 33,
    icon: 'assets/images/i_wage.png',
    iconL: 'assets/images/i_wage_l.png',
    iconS: 'assets/images/i_wage_s.png',
  ),
  CategoryIcon(
    id: 34,
    icon: 'assets/images/i_parttimework.png',
    iconL: 'assets/images/i_parttimework_l.png',
    iconS: 'assets/images/i_parttimework_s.png',
  ),
  CategoryIcon(
    id: 35,
    icon: 'assets/images/i_finance.png',
    iconL: 'assets/images/i_finance_l.png',
    iconS: 'assets/images/i_finance_s.png',
  ),
  CategoryIcon(
    id: 36,
    icon: 'assets/images/i_money.png',
    iconL: 'assets/images/i_money_l.png',
    iconS: 'assets/images/i_money_s.png',
  ),
  CategoryIcon(
    id: 37,
    icon: 'assets/images/i_other.png',
    iconL: 'assets/images/i_other_l.png',
    iconS: 'assets/images/i_other_s.png',
  ),
  // 自定义娱乐 (38-56)
  CategoryIcon(
    id: 38,
    icon: 'assets/images/cc_entertainmente_game.png',
    iconL: 'assets/images/cc_entertainmente_game_l.png',
    iconS: 'assets/images/cc_entertainmente_game_s.png',
  ),
  CategoryIcon(
    id: 39,
    icon: 'assets/images/cc_entertainmente_ping_pong.png',
    iconL: 'assets/images/cc_entertainmente_ping_pong_l.png',
    iconS: 'assets/images/cc_entertainmente_ping_pong_s.png',
  ),
  CategoryIcon(
    id: 40,
    icon: 'assets/images/cc_entertainmente_swimming.png',
    iconL: 'assets/images/cc_entertainmente_swimming_l.png',
    iconS: 'assets/images/cc_entertainmente_swimming_s.png',
  ),
  CategoryIcon(
    id: 41,
    icon: 'assets/images/cc_entertainmente_chess.png',
    iconL: 'assets/images/cc_entertainmente_chess_l.png',
    iconS: 'assets/images/cc_entertainmente_chess_s.png',
  ),
  CategoryIcon(
    id: 42,
    icon: 'assets/images/cc_entertainmente_whirligig.png',
    iconL: 'assets/images/cc_entertainmente_whirligig_l.png',
    iconS: 'assets/images/cc_entertainmente_whirligig_s.png',
  ),
  CategoryIcon(
    id: 43,
    icon: 'assets/images/cc_entertainmente_climbing.png',
    iconL: 'assets/images/cc_entertainmente_climbing_l.png',
    iconS: 'assets/images/cc_entertainmente_climbing_s.png',
  ),
  CategoryIcon(
    id: 44,
    icon: 'assets/images/cc_entertainmente_archery.png',
    iconL: 'assets/images/cc_entertainmente_archery_l.png',
    iconS: 'assets/images/cc_entertainmente_archery_s.png',
  ),
  CategoryIcon(
    id: 45,
    icon: 'assets/images/cc_entertainmente_poker.png',
    iconL: 'assets/images/cc_entertainmente_poker_l.png',
    iconS: 'assets/images/cc_entertainmente_poker_s.png',
  ),
  CategoryIcon(
    id: 46,
    icon: 'assets/images/cc_entertainmente_basketball.png',
    iconL: 'assets/images/cc_entertainmente_basketball_l.png',
    iconS: 'assets/images/cc_entertainmente_basketball_s.png',
  ),
  CategoryIcon(
    id: 47,
    icon: 'assets/images/cc_entertainmente_roller_skating.png',
    iconL: 'assets/images/cc_entertainmente_roller_skating_l.png',
    iconS: 'assets/images/cc_entertainmente_roller_skating_s.png',
  ),
  CategoryIcon(
    id: 48,
    icon: 'assets/images/cc_entertainmente_badminton.png',
    iconL: 'assets/images/cc_entertainmente_badminton_l.png',
    iconS: 'assets/images/cc_entertainmente_badminton_s.png',
  ),
  CategoryIcon(
    id: 49,
    icon: 'assets/images/cc_entertainmente_baseball.png',
    iconL: 'assets/images/cc_entertainmente_baseball_l.png',
    iconS: 'assets/images/cc_entertainmente_baseball_s.png',
  ),
  CategoryIcon(
    id: 50,
    icon: 'assets/images/cc_entertainmente_racing.png',
    iconL: 'assets/images/cc_entertainmente_racing_l.png',
    iconS: 'assets/images/cc_entertainmente_racing_s.png',
  ),
  CategoryIcon(
    id: 51,
    icon: 'assets/images/cc_entertainmente_billiards.png',
    iconL: 'assets/images/cc_entertainmente_billiards_l.png',
    iconS: 'assets/images/cc_entertainmente_billiards_s.png',
  ),
  CategoryIcon(
    id: 52,
    icon: 'assets/images/cc_entertainmente_sailing.png',
    iconL: 'assets/images/cc_entertainmente_sailing_l.png',
    iconS: 'assets/images/cc_entertainmente_sailing_s.png',
  ),
  CategoryIcon(
    id: 53,
    icon: 'assets/images/cc_entertainmente_movies.png',
    iconL: 'assets/images/cc_entertainmente_movies_l.png',
    iconS: 'assets/images/cc_entertainmente_movies_s.png',
  ),
  CategoryIcon(
    id: 54,
    icon: 'assets/images/cc_entertainmente_skiing.png',
    iconL: 'assets/images/cc_entertainmente_skiing_l.png',
    iconS: 'assets/images/cc_entertainmente_skiing_s.png',
  ),
  CategoryIcon(
    id: 55,
    icon: 'assets/images/cc_entertainmente_gambling.png',
    iconL: 'assets/images/cc_entertainmente_gambling_l.png',
    iconS: 'assets/images/cc_entertainmente_gambling_s.png',
  ),
  CategoryIcon(
    id: 56,
    icon: 'assets/images/cc_entertainmente_bowling.png',
    iconL: 'assets/images/cc_entertainmente_bowling_l.png',
    iconS: 'assets/images/cc_entertainmente_bowling_s.png',
  ),
  // 自定义饮食 (57-76)
  CategoryIcon(
    id: 57,
    icon: 'assets/images/cc_catering_ice_lolly.png',
    iconL: 'assets/images/cc_catering_ice_lolly_l.png',
    iconS: 'assets/images/cc_catering_ice_lolly_s.png',
  ),
  CategoryIcon(
    id: 58,
    icon: 'assets/images/cc_catering_banana.png',
    iconL: 'assets/images/cc_catering_banana_l.png',
    iconS: 'assets/images/cc_catering_banana_s.png',
  ),
  CategoryIcon(
    id: 59,
    icon: 'assets/images/cc_catering_chicken.png',
    iconL: 'assets/images/cc_catering_chicken_l.png',
    iconS: 'assets/images/cc_catering_chicken_s.png',
  ),
  CategoryIcon(
    id: 60,
    icon: 'assets/images/cc_catering_apple.png',
    iconL: 'assets/images/cc_catering_apple_l.png',
    iconS: 'assets/images/cc_catering_apple_s.png',
  ),
  CategoryIcon(
    id: 61,
    icon: 'assets/images/cc_catering_sushi.png',
    iconL: 'assets/images/cc_catering_sushi_l.png',
    iconS: 'assets/images/cc_catering_sushi_s.png',
  ),
  CategoryIcon(
    id: 62,
    icon: 'assets/images/cc_catering_noodle.png',
    iconL: 'assets/images/cc_catering_noodle_l.png',
    iconS: 'assets/images/cc_catering_noodle_s.png',
  ),
  CategoryIcon(
    id: 63,
    icon: 'assets/images/cc_catering_beer.png',
    iconL: 'assets/images/cc_catering_beer_l.png',
    iconS: 'assets/images/cc_catering_beer_s.png',
  ),
  CategoryIcon(
    id: 64,
    icon: 'assets/images/cc_catering_bottle.png',
    iconL: 'assets/images/cc_catering_bottle_l.png',
    iconS: 'assets/images/cc_catering_bottle_s.png',
  ),
  CategoryIcon(
    id: 65,
    icon: 'assets/images/cc_catering_drumstick.png',
    iconL: 'assets/images/cc_catering_drumstick_l.png',
    iconS: 'assets/images/cc_catering_drumstick_s.png',
  ),
  CategoryIcon(
    id: 66,
    icon: 'assets/images/cc_catering_birthday_cake.png',
    iconL: 'assets/images/cc_catering_birthday_cake_l.png',
    iconS: 'assets/images/cc_catering_birthday_cake_s.png',
  ),
  CategoryIcon(
    id: 67,
    icon: 'assets/images/cc_catering_rice.png',
    iconL: 'assets/images/cc_catering_rice_l.png',
    iconS: 'assets/images/cc_catering_rice_s.png',
  ),
  CategoryIcon(
    id: 68,
    icon: 'assets/images/cc_catering_skewer.png',
    iconL: 'assets/images/cc_catering_skewer_l.png',
    iconS: 'assets/images/cc_catering_skewer_s.png',
  ),
  CategoryIcon(
    id: 69,
    icon: 'assets/images/cc_catering_tea.png',
    iconL: 'assets/images/cc_catering_tea_l.png',
    iconS: 'assets/images/cc_catering_tea_s.png',
  ),
  CategoryIcon(
    id: 70,
    icon: 'assets/images/cc_catering_red_wine.png',
    iconL: 'assets/images/cc_catering_red_wine_l.png',
    iconS: 'assets/images/cc_catering_red_wine_s.png',
  ),
  CategoryIcon(
    id: 71,
    icon: 'assets/images/cc_catering_cake.png',
    iconL: 'assets/images/cc_catering_cake_l.png',
    iconS: 'assets/images/cc_catering_cake_s.png',
  ),
  CategoryIcon(
    id: 72,
    icon: 'assets/images/cc_catering_hot_pot.png',
    iconL: 'assets/images/cc_catering_hot_pot_l.png',
    iconS: 'assets/images/cc_catering_hot_pot_s.png',
  ),
  CategoryIcon(
    id: 73,
    icon: 'assets/images/cc_catering_hamburg.png',
    iconL: 'assets/images/cc_catering_hamburg_l.png',
    iconS: 'assets/images/cc_catering_hamburg_s.png',
  ),
  CategoryIcon(
    id: 74,
    icon: 'assets/images/cc_catering_seafood.png',
    iconL: 'assets/images/cc_catering_seafood_l.png',
    iconS: 'assets/images/cc_catering_seafood_s.png',
  ),
  CategoryIcon(
    id: 75,
    icon: 'assets/images/cc_catering_ice_cream.png',
    iconL: 'assets/images/cc_catering_ice_cream_l.png',
    iconS: 'assets/images/cc_catering_ice_cream_s.png',
  ),
  CategoryIcon(
    id: 76,
    icon: 'assets/images/cc_catering_coffee.png',
    iconL: 'assets/images/cc_catering_coffee_l.png',
    iconS: 'assets/images/cc_catering_coffee_s.png',
  ),
  // 自定义医疗 (77-86)
  CategoryIcon(
    id: 77,
    icon: 'assets/images/cc_medical_ct.png',
    iconL: 'assets/images/cc_medical_ct_l.png',
    iconS: 'assets/images/cc_medical_ct_s.png',
  ),
  CategoryIcon(
    id: 78,
    icon: 'assets/images/cc_medical_injection.png',
    iconL: 'assets/images/cc_medical_injection_l.png',
    iconS: 'assets/images/cc_medical_injection_s.png',
  ),
  CategoryIcon(
    id: 79,
    icon: 'assets/images/cc_medical_wheelchair.png',
    iconL: 'assets/images/cc_medical_wheelchair_l.png',
    iconS: 'assets/images/cc_medical_wheelchair_s.png',
  ),
  CategoryIcon(
    id: 80,
    icon: 'assets/images/cc_medical_transfusion.png',
    iconL: 'assets/images/cc_medical_transfusion_l.png',
    iconS: 'assets/images/cc_medical_transfusion_s.png',
  ),
  CategoryIcon(
    id: 81,
    icon: 'assets/images/cc_medical_doctor.png',
    iconL: 'assets/images/cc_medical_doctor_l.png',
    iconS: 'assets/images/cc_medical_doctor_s.png',
  ),
  CategoryIcon(
    id: 82,
    icon: 'assets/images/cc_medical_echometer.png',
    iconL: 'assets/images/cc_medical_echometer_l.png',
    iconS: 'assets/images/cc_medical_echometer_s.png',
  ),
  CategoryIcon(
    id: 83,
    icon: 'assets/images/cc_medical_pregnant.png',
    iconL: 'assets/images/cc_medical_pregnant_l.png',
    iconS: 'assets/images/cc_medical_pregnant_s.png',
  ),
  CategoryIcon(
    id: 84,
    icon: 'assets/images/cc_medical_medicine.png',
    iconL: 'assets/images/cc_medical_medicine_l.png',
    iconS: 'assets/images/cc_medical_medicine_s.png',
  ),
  CategoryIcon(
    id: 85,
    icon: 'assets/images/cc_medical_tooth.png',
    iconL: 'assets/images/cc_medical_tooth_l.png',
    iconS: 'assets/images/cc_medical_tooth_s.png',
  ),
  CategoryIcon(
    id: 86,
    icon: 'assets/images/cc_medical_child.png',
    iconL: 'assets/images/cc_medical_child_l.png',
    iconS: 'assets/images/cc_medical_child_s.png',
  ),
  // 自定义学习 (87-96)
  CategoryIcon(
    id: 87,
    icon: 'assets/images/cc_study_school.png',
    iconL: 'assets/images/cc_study_school_l.png',
    iconS: 'assets/images/cc_study_school_s.png',
  ),
  CategoryIcon(
    id: 88,
    icon: 'assets/images/cc_study_lamp.png',
    iconL: 'assets/images/cc_study_lamp_l.png',
    iconS: 'assets/images/cc_study_lamp_s.png',
  ),
  CategoryIcon(
    id: 89,
    icon: 'assets/images/cc_study_blackboard.png',
    iconL: 'assets/images/cc_study_blackboard_l.png',
    iconS: 'assets/images/cc_study_blackboard_s.png',
  ),
  CategoryIcon(
    id: 90,
    icon: 'assets/images/cc_study_guitars.png',
    iconL: 'assets/images/cc_study_guitars_l.png',
    iconS: 'assets/images/cc_study_guitars_s.png',
  ),
  CategoryIcon(
    id: 91,
    icon: 'assets/images/cc_study_calculator.png',
    iconL: 'assets/images/cc_study_calculator_l.png',
    iconS: 'assets/images/cc_study_calculator_s.png',
  ),
  CategoryIcon(
    id: 92,
    icon: 'assets/images/cc_study_penruler.png',
    iconL: 'assets/images/cc_study_penruler_l.png',
    iconS: 'assets/images/cc_study_penruler_s.png',
  ),
  CategoryIcon(
    id: 93,
    icon: 'assets/images/cc_study_book.png',
    iconL: 'assets/images/cc_study_book_l.png',
    iconS: 'assets/images/cc_study_book_s.png',
  ),
  CategoryIcon(
    id: 94,
    icon: 'assets/images/cc_study_hat.png',
    iconL: 'assets/images/cc_study_hat_l.png',
    iconS: 'assets/images/cc_study_hat_s.png',
  ),
  CategoryIcon(
    id: 95,
    icon: 'assets/images/cc_study_piano.png',
    iconL: 'assets/images/cc_study_piano_l.png',
    iconS: 'assets/images/cc_study_piano_s.png',
  ),
  CategoryIcon(
    id: 96,
    icon: 'assets/images/cc_study_penpaper.png',
    iconL: 'assets/images/cc_study_penpaper_l.png',
    iconS: 'assets/images/cc_study_penpaper_s.png',
  ),
  // 自定义交通 (97-111)
  CategoryIcon(
    id: 97,
    icon: 'assets/images/cc_traffic_charge.png',
    iconL: 'assets/images/cc_traffic_charge_l.png',
    iconS: 'assets/images/cc_traffic_charge_s.png',
  ),
  CategoryIcon(
    id: 98,
    icon: 'assets/images/cc_traffic_plane.png',
    iconL: 'assets/images/cc_traffic_plane_l.png',
    iconS: 'assets/images/cc_traffic_plane_s.png',
  ),
  CategoryIcon(
    id: 99,
    icon: 'assets/images/cc_traffic_expressway.png',
    iconL: 'assets/images/cc_traffic_expressway_l.png',
    iconS: 'assets/images/cc_traffic_expressway_s.png',
  ),
  CategoryIcon(
    id: 100,
    icon: 'assets/images/cc_traffic_taxi.png',
    iconL: 'assets/images/cc_traffic_taxi_l.png',
    iconS: 'assets/images/cc_traffic_taxi_s.png',
  ),
  CategoryIcon(
    id: 101,
    icon: 'assets/images/cc_traffic_refuel.png',
    iconL: 'assets/images/cc_traffic_refuel_l.png',
    iconS: 'assets/images/cc_traffic_refuel_s.png',
  ),
  CategoryIcon(
    id: 102,
    icon: 'assets/images/cc_traffic_parking.png',
    iconL: 'assets/images/cc_traffic_parking_l.png',
    iconS: 'assets/images/cc_traffic_parking_s.png',
  ),
  CategoryIcon(
    id: 103,
    icon: 'assets/images/cc_traffic_truck.png',
    iconL: 'assets/images/cc_traffic_truck_l.png',
    iconS: 'assets/images/cc_traffic_truck_s.png',
  ),
  CategoryIcon(
    id: 104,
    icon: 'assets/images/cc_traffic_motorbike.png',
    iconL: 'assets/images/cc_traffic_motorbike_l.png',
    iconS: 'assets/images/cc_traffic_motorbike_s.png',
  ),
  CategoryIcon(
    id: 105,
    icon: 'assets/images/cc_traffic_car.png',
    iconL: 'assets/images/cc_traffic_car_l.png',
    iconS: 'assets/images/cc_traffic_car_s.png',
  ),
  CategoryIcon(
    id: 106,
    icon: 'assets/images/cc_traffic_double_deck_bus.png',
    iconL: 'assets/images/cc_traffic_double_deck_bus_l.png',
    iconS: 'assets/images/cc_traffic_double_deck_bus_s.png',
  ),
  CategoryIcon(
    id: 107,
    icon: 'assets/images/cc_traffic_car_wash.png',
    iconL: 'assets/images/cc_traffic_car_wash_l.png',
    iconS: 'assets/images/cc_traffic_car_wash_s.png',
  ),
  CategoryIcon(
    id: 108,
    icon: 'assets/images/cc_traffic_gasoline.png',
    iconL: 'assets/images/cc_traffic_gasoline_l.png',
    iconS: 'assets/images/cc_traffic_gasoline_s.png',
  ),
  CategoryIcon(
    id: 109,
    icon: 'assets/images/cc_traffic_truck.png',
    iconL: 'assets/images/cc_traffic_truck_l.png',
    iconS: 'assets/images/cc_traffic_truck_s.png',
  ),
  CategoryIcon(
    id: 110,
    icon: 'assets/images/cc_traffic_train.png',
    iconL: 'assets/images/cc_traffic_train_l.png',
    iconS: 'assets/images/cc_traffic_train_s.png',
  ),
  CategoryIcon(
    id: 111,
    icon: 'assets/images/cc_traffic_ship.png',
    iconL: 'assets/images/cc_traffic_ship_l.png',
    iconS: 'assets/images/cc_traffic_ship_s.png',
  ),
  // 自定义购物 (112-139)
  CategoryIcon(
    id: 112,
    icon: 'assets/images/cc_shopping_glasses.png',
    iconL: 'assets/images/cc_shopping_glasses_l.png',
    iconS: 'assets/images/cc_shopping_glasses_s.png',
  ),
  CategoryIcon(
    id: 113,
    icon: 'assets/images/cc_shopping_baby.png',
    iconL: 'assets/images/cc_shopping_baby_l.png',
    iconS: 'assets/images/cc_shopping_baby_s.png',
  ),
  CategoryIcon(
    id: 114,
    icon: 'assets/images/cc_shopping_hand_cream.png',
    iconL: 'assets/images/cc_shopping_hand_cream_l.png',
    iconS: 'assets/images/cc_shopping_hand_cream_s.png',
  ),
  CategoryIcon(
    id: 115,
    icon: 'assets/images/cc_shopping_flowerpot.png',
    iconL: 'assets/images/cc_shopping_flowerpot_l.png',
    iconS: 'assets/images/cc_shopping_flowerpot_s.png',
  ),
  CategoryIcon(
    id: 116,
    icon: 'assets/images/cc_shopping_hat.png',
    iconL: 'assets/images/cc_shopping_hat_l.png',
    iconS: 'assets/images/cc_shopping_hat_s.png',
  ),
  CategoryIcon(
    id: 117,
    icon: 'assets/images/cc_shopping_camera.png',
    iconL: 'assets/images/cc_shopping_camera_l.png',
    iconS: 'assets/images/cc_shopping_camera_s.png',
  ),
  CategoryIcon(
    id: 118,
    icon: 'assets/images/cc_shopping_headset.png',
    iconL: 'assets/images/cc_shopping_headset_l.png',
    iconS: 'assets/images/cc_shopping_headset_s.png',
  ),
  CategoryIcon(
    id: 119,
    icon: 'assets/images/cc_shopping_boots.png',
    iconL: 'assets/images/cc_shopping_boots_l.png',
    iconS: 'assets/images/cc_shopping_boots_s.png',
  ),
  CategoryIcon(
    id: 120,
    icon: 'assets/images/cc_shopping_high_heels.png',
    iconL: 'assets/images/cc_shopping_high_heels_l.png',
    iconS: 'assets/images/cc_shopping_high_heels_s.png',
  ),
  CategoryIcon(
    id: 121,
    icon: 'assets/images/cc_shopping_belt.png',
    iconL: 'assets/images/cc_shopping_belt_l.png',
    iconS: 'assets/images/cc_shopping_belt_s.png',
  ),
  CategoryIcon(
    id: 122,
    icon: 'assets/images/cc_shopping_kettle.png',
    iconL: 'assets/images/cc_shopping_kettle_l.png',
    iconS: 'assets/images/cc_shopping_kettle_s.png',
  ),
  CategoryIcon(
    id: 123,
    icon: 'assets/images/cc_shopping_knickers.png',
    iconL: 'assets/images/cc_shopping_knickers_l.png',
    iconS: 'assets/images/cc_shopping_knickers_s.png',
  ),
  CategoryIcon(
    id: 124,
    icon: 'assets/images/cc_shopping_bikini.png',
    iconL: 'assets/images/cc_shopping_bikini_l.png',
    iconS: 'assets/images/cc_shopping_bikini_s.png',
  ),
  CategoryIcon(
    id: 125,
    icon: 'assets/images/cc_shopping_lipstick.png',
    iconL: 'assets/images/cc_shopping_lipstick_l.png',
    iconS: 'assets/images/cc_shopping_lipstick_s.png',
  ),
  CategoryIcon(
    id: 126,
    icon: 'assets/images/cc_shopping_mascara.png',
    iconL: 'assets/images/cc_shopping_mascara_l.png',
    iconS: 'assets/images/cc_shopping_mascara_s.png',
  ),
  CategoryIcon(
    id: 127,
    icon: 'assets/images/cc_shopping_necklace.png',
    iconL: 'assets/images/cc_shopping_necklace_l.png',
    iconS: 'assets/images/cc_shopping_necklace_s.png',
  ),
  CategoryIcon(
    id: 128,
    icon: 'assets/images/cc_shopping_necktie.png',
    iconL: 'assets/images/cc_shopping_necktie_l.png',
    iconS: 'assets/images/cc_shopping_necktie_s.png',
  ),
  CategoryIcon(
    id: 129,
    icon: 'assets/images/cc_shopping_package.png',
    iconL: 'assets/images/cc_shopping_package_l.png',
    iconS: 'assets/images/cc_shopping_package_s.png',
  ),
  CategoryIcon(
    id: 130,
    icon: 'assets/images/cc_shopping_ring.png',
    iconL: 'assets/images/cc_shopping_ring_l.png',
    iconS: 'assets/images/cc_shopping_ring_s.png',
  ),
  CategoryIcon(
    id: 131,
    icon: 'assets/images/cc_shopping_shopping_trolley.png',
    iconL: 'assets/images/cc_shopping_shopping_trolley_l.png',
    iconS: 'assets/images/cc_shopping_shopping_trolley_s.png',
  ),
  CategoryIcon(
    id: 132,
    icon: 'assets/images/cc_shopping_cosmetics.png',
    iconL: 'assets/images/cc_shopping_cosmetics_l.png',
    iconS: 'assets/images/cc_shopping_cosmetics_s.png',
  ),
  CategoryIcon(
    id: 133,
    icon: 'assets/images/cc_shopping_skirt.png',
    iconL: 'assets/images/cc_shopping_skirt_l.png',
    iconS: 'assets/images/cc_shopping_skirt_s.png',
  ),
  CategoryIcon(
    id: 134,
    icon: 'assets/images/cc_shopping_flower.png',
    iconL: 'assets/images/cc_shopping_flower_l.png',
    iconS: 'assets/images/cc_shopping_flower_s.png',
  ),
  CategoryIcon(
    id: 135,
    icon: 'assets/images/cc_shopping_sneaker.png',
    iconL: 'assets/images/cc_shopping_sneaker_l.png',
    iconS: 'assets/images/cc_shopping_sneaker_s.png',
  ),
  CategoryIcon(
    id: 136,
    icon: 'assets/images/cc_shopping_eye_shadow.png',
    iconL: 'assets/images/cc_shopping_eye_shadow_l.png',
    iconS: 'assets/images/cc_shopping_eye_shadow_s.png',
  ),
  CategoryIcon(
    id: 137,
    icon: 'assets/images/cc_shopping_tie.png',
    iconL: 'assets/images/cc_shopping_tie_l.png',
    iconS: 'assets/images/cc_shopping_tie_s.png',
  ),
  CategoryIcon(
    id: 138,
    icon: 'assets/images/cc_shopping_earrings.png',
    iconL: 'assets/images/cc_shopping_earrings_l.png',
    iconS: 'assets/images/cc_shopping_earrings_s.png',
  ),
  CategoryIcon(
    id: 139,
    icon: 'assets/images/cc_shopping_toiletries.png',
    iconL: 'assets/images/cc_shopping_toiletries_l.png',
    iconS: 'assets/images/cc_shopping_toiletries_s.png',
  ),
  // 自定义生活 (140-151)
  CategoryIcon(
    id: 140,
    icon: 'assets/images/cc_life_moods_of_love.png',
    iconL: 'assets/images/cc_life_moods_of_love_l.png',
    iconS: 'assets/images/cc_life_moods_of_love_s.png',
  ),
  CategoryIcon(
    id: 141,
    icon: 'assets/images/cc_life_hotel.png',
    iconL: 'assets/images/cc_life_hotel_l.png',
    iconS: 'assets/images/cc_life_hotel_s.png',
  ),
  CategoryIcon(
    id: 142,
    icon: 'assets/images/cc_life_bath.png',
    iconL: 'assets/images/cc_life_bath_l.png',
    iconS: 'assets/images/cc_life_bath_s.png',
  ),
  CategoryIcon(
    id: 143,
    icon: 'assets/images/cc_life_buddha.png',
    iconL: 'assets/images/cc_life_buddha_l.png',
    iconS: 'assets/images/cc_life_buddha_s.png',
  ),
  CategoryIcon(
    id: 144,
    icon: 'assets/images/cc_life_candlelight.png',
    iconL: 'assets/images/cc_life_candlelight_l.png',
    iconS: 'assets/images/cc_life_candlelight_s.png',
  ),
  CategoryIcon(
    id: 145,
    icon: 'assets/images/cc_life_sunbath.png',
    iconL: 'assets/images/cc_life_sunbath_l.png',
    iconS: 'assets/images/cc_life_sunbath_s.png',
  ),
  CategoryIcon(
    id: 146,
    icon: 'assets/images/cc_life_tent.png',
    iconL: 'assets/images/cc_life_tent_l.png',
    iconS: 'assets/images/cc_life_tent_s.png',
  ),
  CategoryIcon(
    id: 147,
    icon: 'assets/images/cc_life_tea.png',
    iconL: 'assets/images/cc_life_tea_l.png',
    iconS: 'assets/images/cc_life_tea_s.png',
  ),
  CategoryIcon(
    id: 148,
    icon: 'assets/images/cc_life_trip.png',
    iconL: 'assets/images/cc_life_trip_l.png',
    iconS: 'assets/images/cc_life_trip_s.png',
  ),
  CategoryIcon(
    id: 149,
    icon: 'assets/images/cc_life_date.png',
    iconL: 'assets/images/cc_life_date_l.png',
    iconS: 'assets/images/cc_life_date_s.png',
  ),
  CategoryIcon(
    id: 150,
    icon: 'assets/images/cc_life_spa.png',
    iconL: 'assets/images/cc_life_spa_l.png',
    iconS: 'assets/images/cc_life_spa_s.png',
  ),
  CategoryIcon(
    id: 151,
    icon: 'assets/images/cc_life_holiday.png',
    iconL: 'assets/images/cc_life_holiday_l.png',
    iconS: 'assets/images/cc_life_holiday_s.png',
  ),
  // 自定义个人 (152-162)
  CategoryIcon(
    id: 152,
    icon: 'assets/images/cc_personal_handshake.png',
    iconL: 'assets/images/cc_personal_handshake_l.png',
    iconS: 'assets/images/cc_personal_handshake_s.png',
  ),
  CategoryIcon(
    id: 153,
    icon: 'assets/images/cc_personal_marry.png',
    iconL: 'assets/images/cc_personal_marry_l.png',
    iconS: 'assets/images/cc_personal_marry_s.png',
  ),
  CategoryIcon(
    id: 154,
    icon: 'assets/images/cc_personal_bill.png',
    iconL: 'assets/images/cc_personal_bill_l.png',
    iconS: 'assets/images/cc_personal_bill_s.png',
  ),
  CategoryIcon(
    id: 155,
    icon: 'assets/images/cc_personal_money.png',
    iconL: 'assets/images/cc_personal_money_l.png',
    iconS: 'assets/images/cc_personal_money_s.png',
  ),
  CategoryIcon(
    id: 156,
    icon: 'assets/images/cc_personal_friend.png',
    iconL: 'assets/images/cc_personal_friend_l.png',
    iconS: 'assets/images/cc_personal_friend_s.png',
  ),
  CategoryIcon(
    id: 157,
    icon: 'assets/images/cc_personal_pc.png',
    iconL: 'assets/images/cc_personal_pc_l.png',
    iconS: 'assets/images/cc_personal_pc_s.png',
  ),
  CategoryIcon(
    id: 158,
    icon: 'assets/images/cc_personal_phone.png',
    iconL: 'assets/images/cc_personal_phone_l.png',
    iconS: 'assets/images/cc_personal_phone_s.png',
  ),
  CategoryIcon(
    id: 159,
    icon: 'assets/images/cc_personal_love.png',
    iconL: 'assets/images/cc_personal_love_l.png',
    iconS: 'assets/images/cc_personal_love_s.png',
  ),
  CategoryIcon(
    id: 160,
    icon: 'assets/images/cc_personal_clap.png',
    iconL: 'assets/images/cc_personal_clap_l.png',
    iconS: 'assets/images/cc_personal_clap_s.png',
  ),
  CategoryIcon(
    id: 161,
    icon: 'assets/images/cc_personal_facial.png',
    iconL: 'assets/images/cc_personal_facial_l.png',
    iconS: 'assets/images/cc_personal_facial_s.png',
  ),
  CategoryIcon(
    id: 162,
    icon: 'assets/images/cc_personal_favourite.png',
    iconL: 'assets/images/cc_personal_favourite_l.png',
    iconS: 'assets/images/cc_personal_favourite_s.png',
  ),
  // 自定义家居 (163-177)
  CategoryIcon(
    id: 163,
    icon: 'assets/images/cc_home_bathtub.png',
    iconL: 'assets/images/cc_home_bathtub_l.png',
    iconS: 'assets/images/cc_home_bathtub_s.png',
  ),
  CategoryIcon(
    id: 164,
    icon: 'assets/images/cc_home_renovate.png',
    iconL: 'assets/images/cc_home_renovate_l.png',
    iconS: 'assets/images/cc_home_renovate_s.png',
  ),
  CategoryIcon(
    id: 165,
    icon: 'assets/images/cc_home_washing_machine.png',
    iconL: 'assets/images/cc_home_washing_machine_l.png',
    iconS: 'assets/images/cc_home_washing_machine_s.png',
  ),
  CategoryIcon(
    id: 166,
    icon: 'assets/images/cc_home_tools.png',
    iconL: 'assets/images/cc_home_tools_l.png',
    iconS: 'assets/images/cc_home_tools_s.png',
  ),
  CategoryIcon(
    id: 167,
    icon: 'assets/images/cc_home_water.png',
    iconL: 'assets/images/cc_home_water_l.png',
    iconS: 'assets/images/cc_home_water_s.png',
  ),
  CategoryIcon(
    id: 168,
    icon: 'assets/images/cc_home_bed.png',
    iconL: 'assets/images/cc_home_bed_l.png',
    iconS: 'assets/images/cc_home_bed_s.png',
  ),
  CategoryIcon(
    id: 169,
    icon: 'assets/images/cc_home_sofa.png',
    iconL: 'assets/images/cc_home_sofa_l.png',
    iconS: 'assets/images/cc_home_sofa_s.png',
  ),
  CategoryIcon(
    id: 170,
    icon: 'assets/images/cc_home_air_conditioner.png',
    iconL: 'assets/images/cc_home_air_conditioner_l.png',
    iconS: 'assets/images/cc_home_air_conditioner_s.png',
  ),
  CategoryIcon(
    id: 171,
    icon: 'assets/images/cc_home_wardrobe.png',
    iconL: 'assets/images/cc_home_wardrobe_l.png',
    iconS: 'assets/images/cc_home_wardrobe_s.png',
  ),
  CategoryIcon(
    id: 172,
    icon: 'assets/images/cc_home_bread_machine.png',
    iconL: 'assets/images/cc_home_bread_machine_l.png',
    iconS: 'assets/images/cc_home_bread_machine_s.png',
  ),
  CategoryIcon(
    id: 173,
    icon: 'assets/images/cc_home_microwave_oven.png',
    iconL: 'assets/images/cc_home_microwave_oven_l.png',
    iconS: 'assets/images/cc_home_microwave_oven_s.png',
  ),
  CategoryIcon(
    id: 174,
    icon: 'assets/images/cc_home_bulb.png',
    iconL: 'assets/images/cc_home_bulb_l.png',
    iconS: 'assets/images/cc_home_bulb_s.png',
  ),
  CategoryIcon(
    id: 175,
    icon: 'assets/images/cc_home_w_and_e.png',
    iconL: 'assets/images/cc_home_w_and_e_l.png',
    iconS: 'assets/images/cc_home_w_and_e_s.png',
  ),
  CategoryIcon(
    id: 176,
    icon: 'assets/images/cc_home_hair_drier.png',
    iconL: 'assets/images/cc_home_hair_drier_l.png',
    iconS: 'assets/images/cc_home_hair_drier_s.png',
  ),
  CategoryIcon(
    id: 177,
    icon: 'assets/images/cc_home_refrigerator.png',
    iconL: 'assets/images/cc_home_refrigerator_l.png',
    iconS: 'assets/images/cc_home_refrigerator_s.png',
  ),
  // 自定义家庭 (178-187)
  CategoryIcon(
    id: 178,
    icon: 'assets/images/cc_family_pet_food.png',
    iconL: 'assets/images/cc_family_pet_food_l.png',
    iconS: 'assets/images/cc_family_pet_food_s.png',
  ),
  CategoryIcon(
    id: 179,
    icon: 'assets/images/cc_family_baby_carriage.png',
    iconL: 'assets/images/cc_family_baby_carriage_l.png',
    iconS: 'assets/images/cc_family_baby_carriage_s.png',
  ),
  CategoryIcon(
    id: 180,
    icon: 'assets/images/cc_family_toy_duck.png',
    iconL: 'assets/images/cc_family_toy_duck_l.png',
    iconS: 'assets/images/cc_family_toy_duck_s.png',
  ),
  CategoryIcon(
    id: 181,
    icon: 'assets/images/cc_family_teddy_bear.png',
    iconL: 'assets/images/cc_family_teddy_bear_l.png',
    iconS: 'assets/images/cc_family_teddy_bear_s.png',
  ),
  CategoryIcon(
    id: 182,
    icon: 'assets/images/cc_family_feeding_bottle.png',
    iconL: 'assets/images/cc_family_feeding_bottle_l.png',
    iconS: 'assets/images/cc_family_feeding_bottle_s.png',
  ),
  CategoryIcon(
    id: 183,
    icon: 'assets/images/cc_family_pet_home.png',
    iconL: 'assets/images/cc_family_pet_home_l.png',
    iconS: 'assets/images/cc_family_pet_home_s.png',
  ),
  CategoryIcon(
    id: 184,
    icon: 'assets/images/cc_family_baby.png',
    iconL: 'assets/images/cc_family_baby_l.png',
    iconS: 'assets/images/cc_family_baby_s.png',
  ),
  CategoryIcon(
    id: 185,
    icon: 'assets/images/cc_family_dog.png',
    iconL: 'assets/images/cc_family_dog_l.png',
    iconS: 'assets/images/cc_family_dog_s.png',
  ),
  CategoryIcon(
    id: 186,
    icon: 'assets/images/cc_family_nipple.png',
    iconL: 'assets/images/cc_family_nipple_l.png',
    iconS: 'assets/images/cc_family_nipple_s.png',
  ),
  CategoryIcon(
    id: 187,
    icon: 'assets/images/cc_family_wooden_horse.png',
    iconL: 'assets/images/cc_family_wooden_horse_l.png',
    iconS: 'assets/images/cc_family_wooden_horse_s.png',
  ),
  // 自定义健身 (188-199)
  CategoryIcon(
    id: 188,
    icon: 'assets/images/cc_fitness_skating.png',
    iconL: 'assets/images/cc_fitness_skating_l.png',
    iconS: 'assets/images/cc_fitness_skating_s.png',
  ),
  CategoryIcon(
    id: 189,
    icon: 'assets/images/cc_fitness_treadmills.png',
    iconL: 'assets/images/cc_fitness_treadmills_l.png',
    iconS: 'assets/images/cc_fitness_treadmills_s.png',
  ),
  CategoryIcon(
    id: 190,
    icon: 'assets/images/cc_fitness_barbell.png',
    iconL: 'assets/images/cc_fitness_barbell_l.png',
    iconS: 'assets/images/cc_fitness_barbell_s.png',
  ),
  CategoryIcon(
    id: 191,
    icon: 'assets/images/cc_fitness_fitball.png',
    iconL: 'assets/images/cc_fitness_fitball_l.png',
    iconS: 'assets/images/cc_fitness_fitball_s.png',
  ),
  CategoryIcon(
    id: 192,
    icon: 'assets/images/cc_fitness_elliptical_machine.png',
    iconL: 'assets/images/cc_fitness_elliptical_machine_l.png',
    iconS: 'assets/images/cc_fitness_elliptical_machine_s.png',
  ),
  CategoryIcon(
    id: 193,
    icon: 'assets/images/cc_fitness_bodybuilding.png',
    iconL: 'assets/images/cc_fitness_bodybuilding_l.png',
    iconS: 'assets/images/cc_fitness_bodybuilding_s.png',
  ),
  CategoryIcon(
    id: 194,
    icon: 'assets/images/cc_fitness_weightlifting.png',
    iconL: 'assets/images/cc_fitness_weightlifting_l.png',
    iconS: 'assets/images/cc_fitness_weightlifting_s.png',
  ),
  CategoryIcon(
    id: 195,
    icon: 'assets/images/cc_fitness_running.png',
    iconL: 'assets/images/cc_fitness_running_l.png',
    iconS: 'assets/images/cc_fitness_running_s.png',
  ),
  CategoryIcon(
    id: 196,
    icon: 'assets/images/cc_fitness_boxing.png',
    iconL: 'assets/images/cc_fitness_boxing_l.png',
    iconS: 'assets/images/cc_fitness_boxing_s.png',
  ),
  CategoryIcon(
    id: 197,
    icon: 'assets/images/cc_fitness_sit_in.png',
    iconL: 'assets/images/cc_fitness_sit_in_l.png',
    iconS: 'assets/images/cc_fitness_sit_in_s.png',
  ),
  CategoryIcon(
    id: 198,
    icon: 'assets/images/cc_fitness_dumbbell.png',
    iconL: 'assets/images/cc_fitness_dumbbell_l.png',
    iconS: 'assets/images/cc_fitness_dumbbell_s.png',
  ),
  CategoryIcon(
    id: 199,
    icon: 'assets/images/cc_fitness_hand_muscle_developer.png',
    iconL: 'assets/images/cc_fitness_hand_muscle_developer_l.png',
    iconS: 'assets/images/cc_fitness_hand_muscle_developer_s.png',
  ),
  // 自定义办公 (200-208)
  CategoryIcon(
    id: 200,
    icon: 'assets/images/cc_office_mouse.png',
    iconL: 'assets/images/cc_office_mouse_l.png',
    iconS: 'assets/images/cc_office_mouse_s.png',
  ),
  CategoryIcon(
    id: 201,
    icon: 'assets/images/cc_office_computer.png',
    iconL: 'assets/images/cc_office_computer_l.png',
    iconS: 'assets/images/cc_office_computer_s.png',
  ),
  CategoryIcon(
    id: 202,
    icon: 'assets/images/cc_office_clip.png',
    iconL: 'assets/images/cc_office_clip_l.png',
    iconS: 'assets/images/cc_office_clip_s.png',
  ),
  CategoryIcon(
    id: 203,
    icon: 'assets/images/cc_office_keyboard.png',
    iconL: 'assets/images/cc_office_keyboard_l.png',
    iconS: 'assets/images/cc_office_keyboard_s.png',
  ),
  CategoryIcon(
    id: 204,
    icon: 'assets/images/cc_office_drawing_board.png',
    iconL: 'assets/images/cc_office_drawing_board_l.png',
    iconS: 'assets/images/cc_office_drawing_board_s.png',
  ),
  CategoryIcon(
    id: 205,
    icon: 'assets/images/cc_office_desk.png',
    iconL: 'assets/images/cc_office_desk_l.png',
    iconS: 'assets/images/cc_office_desk_s.png',
  ),
  CategoryIcon(
    id: 206,
    icon: 'assets/images/cc_office_pen_container.png',
    iconL: 'assets/images/cc_office_pen_container_l.png',
    iconS: 'assets/images/cc_office_pen_container_s.png',
  ),
  CategoryIcon(
    id: 207,
    icon: 'assets/images/cc_office_printer.png',
    iconL: 'assets/images/cc_office_printer_l.png',
    iconS: 'assets/images/cc_office_printer_s.png',
  ),
  CategoryIcon(
    id: 208,
    icon: 'assets/images/cc_office_pen_ruler.png',
    iconL: 'assets/images/cc_office_pen_ruler_l.png',
    iconS: 'assets/images/cc_office_pen_ruler_s.png',
  ),
  // 自定义收入 (209-218)
  CategoryIcon(
    id: 209,
    icon: 'assets/images/cc_income_1.png',
    iconL: 'assets/images/cc_income_1_l.png',
    iconS: 'assets/images/cc_income_1_s.png',
  ),
  CategoryIcon(
    id: 210,
    icon: 'assets/images/cc_income_2.png',
    iconL: 'assets/images/cc_income_2_l.png',
    iconS: 'assets/images/cc_income_2_s.png',
  ),
  CategoryIcon(
    id: 211,
    icon: 'assets/images/cc_income_3.png',
    iconL: 'assets/images/cc_income_3_l.png',
    iconS: 'assets/images/cc_income_3_s.png',
  ),
  CategoryIcon(
    id: 212,
    icon: 'assets/images/cc_income_4.png',
    iconL: 'assets/images/cc_income_4_l.png',
    iconS: 'assets/images/cc_income_4_s.png',
  ),
  CategoryIcon(
    id: 213,
    icon: 'assets/images/cc_income_5.png',
    iconL: 'assets/images/cc_income_5_l.png',
    iconS: 'assets/images/cc_income_5_s.png',
  ),
  CategoryIcon(
    id: 214,
    icon: 'assets/images/cc_income_6.png',
    iconL: 'assets/images/cc_income_6_l.png',
    iconS: 'assets/images/cc_income_6_s.png',
  ),
  CategoryIcon(
    id: 215,
    icon: 'assets/images/cc_income_7.png',
    iconL: 'assets/images/cc_income_7_l.png',
    iconS: 'assets/images/cc_income_7_s.png',
  ),
  CategoryIcon(
    id: 216,
    icon: 'assets/images/cc_income_8.png',
    iconL: 'assets/images/cc_income_8_l.png',
    iconS: 'assets/images/cc_income_8_s.png',
  ),
  CategoryIcon(
    id: 217,
    icon: 'assets/images/cc_income_9.png',
    iconL: 'assets/images/cc_income_9_l.png',
    iconS: 'assets/images/cc_income_9_s.png',
  ),
  CategoryIcon(
    id: 218,
    icon: 'assets/images/cc_income_10.png',
    iconL: 'assets/images/cc_income_10_l.png',
    iconS: 'assets/images/cc_income_10_s.png',
  ),
  // 自定义其他 (219-225)
  CategoryIcon(
    id: 219,
    icon: 'assets/images/cc_other_diamond.png',
    iconL: 'assets/images/cc_other_diamond_l.png',
    iconS: 'assets/images/cc_other_diamond_s.png',
  ),
  CategoryIcon(
    id: 220,
    icon: 'assets/images/cc_other_memorial_day.png',
    iconL: 'assets/images/cc_other_memorial_day_l.png',
    iconS: 'assets/images/cc_other_memorial_day_s.png',
  ),
  CategoryIcon(
    id: 221,
    icon: 'assets/images/cc_other_flag.png',
    iconL: 'assets/images/cc_other_flag_l.png',
    iconS: 'assets/images/cc_other_flag_s.png',
  ),
  CategoryIcon(
    id: 222,
    icon: 'assets/images/cc_other_crown.png',
    iconL: 'assets/images/cc_other_crown_l.png',
    iconS: 'assets/images/cc_other_crown_s.png',
  ),
  CategoryIcon(
    id: 223,
    icon: 'assets/images/cc_other_zongzi.png',
    iconL: 'assets/images/cc_other_zongzi_l.png',
    iconS: 'assets/images/cc_other_zongzi_s.png',
  ),
  CategoryIcon(
    id: 224,
    icon: 'assets/images/cc_other_lantern.png',
    iconL: 'assets/images/cc_other_lantern_l.png',
    iconS: 'assets/images/cc_other_lantern_s.png',
  ),
  CategoryIcon(
    id: 225,
    icon: 'assets/images/cc_other_firecracker.png',
    iconL: 'assets/images/cc_other_firecracker_l.png',
    iconS: 'assets/images/cc_other_firecracker_s.png',
  ),
];

CategoryIcon? getIconById(int id) {
  if (id < 0 || id >= iconJson.length) return null;
  return iconJson[id];
}
