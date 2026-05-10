# 需求文档

## Introduction

鲨鱼记账 App 是一款面向个人用户的移动端记账应用，支持 iOS 和 Android 双平台（基于 React Native 或 Flutter 跨平台技术栈）。应用采用离线优先架构，所有数据默认存储在本地 SQLite 数据库中，保障用户数据隐私与安全。

核心目标是帮助用户快速记录日常收支、管理多个账本与账户、设置预算目标，并通过可视化报表直观了解个人财务状况。

---

## 词汇表

- **App**：鲨鱼记账移动端应用程序
- **记录（Record）**：一条收入或支出的流水记录，包含金额、分类、账户、日期、备注等字段
- **账本（Ledger）**：用于归组记录的容器，用户可创建多个账本（如日常账本、旅行账本）
- **账户（Account）**：代表资金来源或去向的实体（如现金、银行卡、支付宝、微信钱包）
- **分类（Category）**：对记录进行语义归类的标签（如餐饮、交通、工资）
- **预算（Budget）**：用户为特定时间段（月度）设定的支出上限
- **统计报表（Report）**：对记录数据进行聚合计算后生成的可视化图表与数据摘要
- **本地存储（Local_Storage）**：设备本地的 SQLite 数据库，不依赖网络连接
- **备份文件（Backup_File）**：包含全量数据的可导入导出文件，格式为 JSON
- **导出文件（Export_File）**：以 Excel（.xlsx）或 CSV 格式生成的报表文件

---

## Requirements

### Requirement 1：收支记录管理

**User Story:** 作为一名用户，我希望能够快速添加、编辑和删除收支记录，以便准确追踪我的每一笔财务流水。

#### Acceptance Criteria

1. WHEN 用户点击"添加记录"按钮，THE App SHALL 在 300ms 内展示记录录入表单，表单包含金额、类型（收入/支出）、分类、账户、日期、备注、图片附件字段。
2. WHEN 用户提交记录表单且金额字段为空或为零，THE App SHALL 阻止提交并显示"金额不能为空或零"的错误提示。
3. WHEN 用户提交合法的记录表单，THE App SHALL 将记录持久化到 Local_Storage 并在 500ms 内返回记录列表页面。
4. WHEN 用户为记录添加图片附件，THE App SHALL 支持从相册选择或调用相机拍摄，且单张图片大小不超过 10MB。
5. WHEN 用户选择编辑已有记录，THE App SHALL 预填充该记录的所有字段并允许修改任意字段。
6. WHEN 用户确认删除一条记录，THE App SHALL 从 Local_Storage 中永久移除该记录并更新相关 Account 余额。
7. IF Local_Storage 写入失败，THEN THE App SHALL 显示"保存失败，请重试"的错误提示，并保留用户已填写的表单内容。

---

### Requirement 2：分类管理

**User Story:** 作为一名用户，我希望能够使用预设分类并自定义分类，以便按照自己的消费习惯对记录进行归类。

#### Acceptance Criteria

1. THE App SHALL 在首次启动时预置以下支出 Category：餐饮、交通、购物、娱乐、居家、医疗、教育、旅行；以及以下收入 Category：工资、兼职、理财、红包、其他收入。
2. WHEN 用户创建自定义 Category，THE App SHALL 要求用户输入分类名称（1–16 个字符）并从内置图标库中选择一个图标。
3. WHEN 用户提交的自定义 Category 名称与已有 Category 名称重复，THE App SHALL 阻止创建并提示"分类名称已存在"。
4. THE App SHALL 支持用户对自定义 Category 进行重命名和更换图标。
5. WHEN 用户尝试删除一个已被 Record 引用的 Category，THE App SHALL 提示用户该 Category 下存在 Record，并要求用户先将相关 Record 迁移到其他 Category 或确认强制删除。
6. THE App SHALL 支持用户通过拖拽调整 Category 的显示顺序。

---

### Requirement 3：多账本管理

**User Story:** 作为一名用户，我希望能够创建和管理多个独立账本，以便将不同场景（日常、旅行、家庭）的收支分开统计。

#### Acceptance Criteria

1. THE App SHALL 在首次启动时自动创建一个名为"日常账本"的默认 Ledger。
2. WHEN 用户创建新 Ledger，THE App SHALL 要求用户输入账本名称（1–20 个字符）并可选择封面颜色或图标。
3. THE App SHALL 支持用户同时拥有最多 20 个 Ledger。
4. WHEN 用户切换当前 Ledger，THE App SHALL 在 300ms 内刷新所有 Record 列表和统计数据以反映所选 Ledger 的数据。
5. THE App SHALL 保证各 Ledger 的 Record、统计、Budget 数据相互独立，不产生交叉。
6. WHEN 用户删除一个 Ledger，THE App SHALL 提示该 Ledger 下的所有 Record 将被永久删除，并要求用户二次确认后方可执行删除。
7. IF 用户尝试删除唯一剩余的 Ledger，THEN THE App SHALL 阻止删除并提示"至少需要保留一个账本"。

---

### Requirement 4：账户管理

**User Story:** 作为一名用户，我希望能够管理多个资金账户并追踪各账户余额，以便全面掌握我的资产状况。

#### Acceptance Criteria

1. THE App SHALL 在首次启动时预置以下 Account：现金、银行卡、支付宝、微信钱包。
2. WHEN 用户创建自定义 Account，THE App SHALL 要求用户输入账户名称（1–20 个字符）、账户类型（现金/银行卡/电子钱包/其他）和初始余额。
3. WHEN 一条支出 Record 被保存，THE App SHALL 将该 Record 关联 Account 的余额减去 Record 金额。
4. WHEN 一条收入 Record 被保存，THE App SHALL 将该 Record 关联 Account 的余额加上 Record 金额。
5. WHEN 一条 Record 被删除或修改，THE App SHALL 相应地回滚或重新计算关联 Account 的余额，保证余额与 Record 数据一致。
6. THE App SHALL 在账户列表页面展示每个 Account 的当前余额和账户类型图标。
7. WHEN 用户删除一个 Account，THE App SHALL 提示该 Account 下的所有 Record 将被保留但账户字段将标记为"已删除账户"，并要求用户确认。

---

### Requirement 5：预算管理

**User Story:** 作为一名用户，我希望能够设置月度预算并在超支时收到提醒，以便控制消费、实现储蓄目标。

#### Acceptance Criteria

1. THE App SHALL 支持用户为当前 Ledger 设置月度总 Budget（单位：元，精度：分）。
2. THE App SHALL 支持用户为当前 Ledger 的每个支出 Category 单独设置月度 Budget。
3. WHILE 当月支出总额超过月度总 Budget 的 80%，THE App SHALL 在首页以橙色展示预算进度条。
4. WHEN 当月支出总额超过月度总 Budget，THE App SHALL 推送本地通知"本月预算已超支"并在首页以红色展示预算进度条。
5. WHEN 某 Category 当月支出超过该 Category 的 Budget，THE App SHALL 在分类预算列表中以红色标记该 Category 并显示超支金额。
6. WHEN 用户未设置 Budget，THE App SHALL 不显示预算相关的进度条和提醒。
7. THE App SHALL 在每月第一天自动重置当月 Budget 的已用金额统计，历史月份的预算执行数据予以保留。

---

### Requirement 6：统计报表

**User Story:** 作为一名用户，我希望能够通过图表查看不同时间维度的收支统计，以便分析消费规律和财务趋势。

#### Acceptance Criteria

1. THE App SHALL 支持按日、周、月、年四个时间维度展示收支统计 Report。
2. WHEN 用户查看月度 Report，THE App SHALL 展示当月总收入、总支出、结余，以及支出 Category 占比饼图和每日支出柱状图。
3. WHEN 用户查看年度 Report，THE App SHALL 展示全年各月收支对比折线图和年度总收入、总支出、结余。
4. THE App SHALL 在 Report 页面展示支出 Category 排行榜，按金额从高到低排列，并显示各 Category 占总支出的百分比。
5. WHEN 用户点击图表中的某个数据点或 Category，THE App SHALL 展示该数据点或 Category 下的具体 Record 列表。
6. WHEN 所选时间范围内无任何 Record，THE App SHALL 显示"暂无数据"的空状态提示，而非空白图表。
7. THE App SHALL 在 1 秒内完成统计数据的计算和图表渲染（基于本地数据，Record 数量不超过 10,000 条）。

---

### Requirement 7：日历视图

**User Story:** 作为一名用户，我希望能够在日历上直观查看每天的收支情况，以便快速定位特定日期的财务记录。

#### Acceptance Criteria

1. THE App SHALL 提供月历视图，在每个日期格内显示当日的支出合计金额（若有支出 Record）。
2. WHEN 用户点击日历上的某一天，THE App SHALL 展示该日所有 Record 的详细列表，包含金额、Category 图标、备注。
3. WHEN 某天同时存在收入和支出 Record，THE App SHALL 在日期格内分别以绿色显示收入合计、红色显示支出合计。
4. THE App SHALL 支持用户通过左右滑动或点击箭头在月份之间切换。
5. WHEN 用户在日历视图中点击某天的 Record，THE App SHALL 跳转到该 Record 的详情/编辑页面。

---

### Requirement 8：数据导出

**User Story:** 作为一名用户，我希望能够将记账数据导出为通用格式，以便在电脑上进行进一步分析或存档。

#### Acceptance Criteria

1. THE App SHALL 支持将当前 Ledger 的 Record 导出为 CSV 格式的 Export_File，文件包含以下列：日期、类型、金额、Category、Account、备注。
2. THE App SHALL 支持将当前 Ledger 的 Record 导出为 Excel（.xlsx）格式的 Export_File，格式与 CSV 一致。
3. WHEN 用户触发导出操作，THE App SHALL 允许用户选择导出的时间范围（全部、本月、本年、自定义范围）。
4. WHEN Export_File 生成完成，THE App SHALL 调用系统分享菜单，允许用户将文件保存到本地或通过第三方应用发送。
5. WHEN 所选时间范围内无 Record，THE App SHALL 提示"所选范围内无数据可导出"并取消导出操作。
6. IF 导出过程中发生文件写入错误，THEN THE App SHALL 显示"导出失败，请检查存储权限"的错误提示。

---

### Requirement 9：定时记账提醒

**User Story:** 作为一名用户，我希望能够设置定时提醒，以便养成每日记账的习惯。

#### Acceptance Criteria

1. THE App SHALL 支持用户开启或关闭每日记账提醒。
2. WHEN 用户开启提醒，THE App SHALL 要求用户设置提醒时间（精确到分钟）。
3. WHEN 到达用户设定的提醒时间，THE App SHALL 推送本地通知，通知内容为"该记账啦，记录今天的收支吧"。
4. WHEN 用户点击提醒通知，THE App SHALL 直接跳转到添加 Record 页面。
5. WHERE 用户设备的系统通知权限被关闭，THE App SHALL 在提醒设置页面显示"请在系统设置中开启通知权限"的引导提示。
6. THE App SHALL 支持用户设置最多 5 个不同时间的提醒。

---

### Requirement 10：数据安全与备份恢复

**User Story:** 作为一名用户，我希望能够备份和恢复我的记账数据，以便在更换设备或数据丢失时找回历史记录。

#### Acceptance Criteria

1. THE App SHALL 将所有数据存储在设备本地的 SQLite 数据库中，不向任何远程服务器上传用户数据（除非用户主动触发导出/分享操作）。
2. THE App SHALL 支持用户将全量数据导出为 JSON 格式的 Backup_File，文件包含所有 Ledger、Account、Category、Record 数据。
3. WHEN 用户导入 Backup_File，THE App SHALL 校验文件格式的合法性，若格式不合法则显示"备份文件格式错误，无法导入"。
4. WHEN 用户导入合法的 Backup_File，THE App SHALL 提示用户选择"覆盖现有数据"或"合并到现有数据"两种导入模式。
5. WHEN 用户选择"覆盖现有数据"模式导入，THE App SHALL 在执行覆盖前再次要求用户确认，并提示"此操作将清除所有现有数据且不可撤销"。
6. WHEN Backup_File 导入成功，THE App SHALL 显示导入摘要，包含导入的 Ledger 数、Account 数、Category 数、Record 数。
7. IF 导入过程中发生错误，THEN THE App SHALL 回滚所有已导入的数据，保证数据库处于导入前的一致状态，并显示具体错误信息。
8. THE App SHALL 支持用户设置自动备份，可选频率为每天、每周、每月，Backup_File 保存到设备本地指定目录。

---

### Requirement 11：数据序列化与反序列化

**User Story:** 作为开发者，我希望应用具备健壮的数据序列化与反序列化能力，以便保证 Backup_File 的可靠导入导出。

#### Acceptance Criteria

1. THE App SHALL 将内部数据模型序列化为 JSON 格式时，保留所有字段的类型信息（金额使用字符串表示以避免浮点精度丢失）。
2. WHEN 反序列化 JSON Backup_File，THE App SHALL 将 JSON 解析为内部数据模型对象。
3. THE App SHALL 提供格式化输出能力，将内部数据模型格式化为人类可读的 JSON 字符串（含缩进）。
4. FOR ALL 合法的内部数据模型对象，执行"序列化 → 格式化输出 → 反序列化"操作后，THE App SHALL 产生与原始对象语义等价的对象（往返属性）。
