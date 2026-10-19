# eCAT · 喵喵管家 — 项目进度文档

> 更新时间：2026-10-19
> 当前状态：**v1.5.2 发布（全局触动反馈已真机验收）**

---

## 一、项目定位

面向**养猫女生**的可爱风猫咪管理 App。

- **UI 可爱**：奶油白 + 樱花粉配色、大圆角卡片、猫爪元素、emoji 头像
- **交互容易**：大按钮点选、少打字、快捷记录三合一弹窗
- **功能干货**：喂食/体重/健康记录 + 疫苗驱虫提醒 + 养猫百科
- **核心设计**：**以猫咪为中心的数据隔离** —— 每只猫独立档案，所有记录通过 `catId` 挂载，切换猫咪即切换整套数据视图（一猫一档、个性化服务）

## 二、技术栈

| 项 | 内容 |
|---|---|
| 框架 | Flutter 3.44.9 stable（Dart 3.12） |
| 状态管理 | provider 6.x（`CatStore` + `SettingsStore` 均 extends ChangeNotifier） |
| 本地存储 | shared_preferences 2.5（JSON 序列化） |
| 图表 | fl_chart 1.2.0（体重曲线） |
| 日期 | intl 0.20（zh_CN） |
| 通知 | flutter_local_notifications 22.3 + timezone 0.11（健康提醒） |
| 平台 | Windows（已编译）+ Android（工程已就绪，待测试） |

## 三、目录结构

```
eCAT/
├── lib/
│   ├── main.dart              # App 入口 + 引导门控 + 底部四 Tab 骨架 + 主题模式接线
│   ├── models/cat.dart        # Cat / FeedLog / WeightLog / HealthLog 数据模型
│   ├── store/cat_store.dart   # 全局状态：多猫管理、catId 隔离查询、持久化
│   ├── store/settings_store.dart # 全局设置：引导标记 / 主题模式 / 通知开关
│   ├── services/reminder_service.dart # 本地提醒通知：定时调度 + 启动补发 + 去重
│   ├── theme/app_theme.dart   # 可爱主题（AppPalette 双调色板 + AppColors 动态取色 + 明暗 ThemeData）
│   ├── widgets/common.dart    # CuteCard / PawButton / CatAvatar / ChipChoice /
│   │                          # EmptyState / SectionTitle / showCuteSheet / showCuteToast
│   └── pages/
│       ├── home_page.dart     # Tab1「今天」：问候、档案卡、喂食进度、健康倒计时
│       ├── record_page.dart   # Tab2「记录」：合并时间线 + 筛选 + 长按删除
│       ├── cat_page.dart      # Tab3「猫咪」：多猫管理 + 表单 + 详情(体重曲线/健康时间线) + 设置入口
│       ├── knowledge_page.dart# Tab4「知识」：禁食红黑榜/疫苗表/健康自查/新手清单
│       ├── quick_record.dart  # 快捷记录弹窗（喂食/体重/健康三合一，FAB 共用）
│       ├── onboarding_page.dart # 首次引导页（3 页 PageView）
│       └── settings_sheet.dart  # 设置弹层（通知开关 + 外观选择）
└── test/                      # 冒烟测试 + 引导页测试 + SettingsStore 单元测试
```

## 四、已完成功能 ✅

### 数据层
- [x] `Cat` 档案：名字/品种/生日/性别/绝育/毛色/emoji头像/目标体重/过敏禁忌/备注，`ageText()` 自动算猫龄
- [x] `FeedLog` 喂食：干粮/湿粮罐头/冻干/零食/饮水 五类 + 克数 + 备注
- [x] `WeightLog` 体重：同日去重、按日期排序
- [x] `HealthLog` 健康：疫苗/驱虫/洗澡/就医/症状 五类 + `nextDue` 下次提醒时间
- [x] 全部数据 JSON 持久化，按 `catId` 隔离；删除猫咪级联清理其所有记录

### 页面
- [x] **今天**：时段问候、多猫切换、档案大卡（体重/目标对比「距目标还差 0.3kg」）、今日喂食进度条（60g 建议量）+ 明细、健康提醒倒计时（过期红/今天黄/未来绿）
- [x] **记录**：三类记录合并时间线倒序、类型筛选胶囊、长按删除（二次确认）
- [x] **猫咪**：卡片列表（性别徽章/绝育标签/最新体重）、添加/编辑表单（10 emoji 头像、品种快捷胶囊、日期选择器、性别/绝育/毛色/目标体重/过敏/备注）、详情页（**fl_chart 体重曲线**含目标虚线参考线 + 健康时间线 + 温柔删除确认）
- [x] **知识**：17 条禁食红黑榜（红/黄/绿分级）、疫苗时间表（2/3/4 月龄三联+狂犬+驱虫）、6 条健康自查（症状→原因→建议）、10 条可勾选新手清单（带进度）
- [x] 快捷记录弹窗：喂食/体重/健康三 Tab，常用量快捷按钮，无猫时引导

### 质量验证
- [x] `flutter analyze`：**0 issues**
- [x] `flutter test`：**All tests passed**
- [x] `flutter build windows --release`：**√ Built ecat.exe**（约 30MB）

## 五、已修复的 Bug 🐛

| Bug | 根因 | 修复 |
|---|---|---|
| 添加猫咪弹窗显示不全，保存按钮不可见 | `showCuteSheet` 外层 Column `mainAxisSize: min` + `isScrollControlled: true`，长表单无高度约束导致溢出 | 弹窗容器加 `ConstrainedBox(maxHeight: 屏高 90%)` + 内容包 `Flexible`，内部滚动生效（所有弹窗统一受益） |

## 六、环境备忘 ⚠️（本机踩坑记录）

1. **Flutter 不在 PATH**：SDK 位于 `D:\flutter`，命令前需 `export PATH="/d/flutter/bin:$PATH"`
2. **国内网络**：需设置中国镜像，否则引擎下载挂起：
   ```bash
   export PUB_HOSTED_URL=https://pub.flutter-io.cn
   export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   ```
3. **Windows 开发者模式必须开启**：否则插件符号链接创建失败，`flutter build windows` 静默卡死（verbose 才能看到报错）。已通过注册表 `HKLM\...\AppModelUnlock\AllowDevelopmentWithoutDevLicense=1` 开启
4. **编译产物**：`build\windows\x64\runner\Release\ecat.exe`

## 七、待办：打磨方向 📋（按建议优先级）

### P1 — 观感与个性化（2026-10-18 批次 `feat/p1-polish` 已实现，待验收）
- [x] **App 图标**：粉色猫爪图标（`tool/make_icon.py` 生成源图 + flutter_launcher_icons），Windows ico + Android 自适应双端
- [x] **每日喂食目标个性化**：`Cat.dailyFoodGoal`（默认 60g，旧数据兼容），猫咪表单可设，首页进度条按当前猫目标计算
- [x] **打卡动效**：`showPawCelebration` 猫爪印弹跳 + 彩色粒子扩散，接入全部 5 个保存成功点

### P2 — 数据服务（2026-10-18 批次已合并 v1.3.0）
- [x] **数据备份导出/导入**：JSON 文件导出导入，迁移手机端时直接带走数据
- [x] **统计面板**：周/月喂食量统计、体重周报（「这周胖了 0.2kg 🎉」）
- [x] **照片头像**：除 emoji 外支持本地照片（image_picker + file_selector 跨端）

### P3 — 提醒与体验（2026-10-19 批次 `feat/p3-reminders-experience` 已合并 v1.4.0）
- [x] **首次引导页**：3 页 onboarding（欢迎/一猫一档/提醒与备份），SettingsStore.onboardingDone 门控，跳过/完成均写入 —— ✅ 已验收（2026-10-19）
- [x] **深色模式**：AppPalette 双调色板（暖夜色底 + 降饱和粉），AppColors 动态取色（调用点语法不变），AppTheme.dark + themeMode 三态切换，139 处 const 级联修复 + Colors.white 硬编码清理 —— ✅ 已验收（2026-10-19）
- [x] **设置弹层**：猫咪页顶栏 ⚙️ → 通知开关 + 外观选择（跟随系统/浅色/深色）—— ✅ 已验收（2026-10-19）
- [x] **本地提醒通知**：flutter_local_notifications 22.3 + timezone；Android 定时到到期日 09:00（inexactAllowWhileIdle 免精确闹钟权限），Windows 同样支持一次性定时（插件原生 zonedSchedule）+ 启动补发「今天到期/过期≤7天未提醒过」条目（SP 标记去重）；通知开关在设置弹层，Android 13+ 运行时请求权限 —— ⚠️ **伪验收（2026-10-19）**：功能已实现、构建通过，但 Windows 端未实际触发通知验证；待 P4 批次真机/真实场景转正

### P4 — 通知落地与 Android 回归（2026-10-19 批次 `feat/p4-notify-verify`）
- [x] **通知测试入口**：设置弹层长按通知卡片发一条测试通知（验证链路用，代码保留）
- [x] **Android 端 v1.4 适配**：flutter_local_notifications 要求 core library desugaring（build.gradle.kts 启用 + desugar_jdk_libs 2.1.4）；R8 keep 规则补 com.dexterous.** + gson（Gson 反射序列化字段名即 JSON key，混淆后定时通知静默失效）；mapping.txt 验证 NotificationDetails/Receiver/Continuation 均原名保留
- [x] **Android 权限声明**：主 manifest 显式 POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED（开机恢复定时提醒）
- [x] **APK 发版**：`flutter build apk --release` 成功（53.4MB），归档 `releases/ecat-v1.4.0-android.apk`
- [x] **Android 真机验证**：v1.5.2 APK 真机安装验收通过（2026-10-19，引导页/深色/触动反馈均正常）

### P5 — 记录编辑与提醒扩展（2026-10-19 批次 `feat/p5-edit-reminders` 已合并 v1.5.0）
- [x] **记录编辑**：CatStore 新增 updateFeed/updateWeight/updateHealth（按 id 整条替换，体重保留同日去重）；快捷记录弹窗支持编辑模式（预填表单、锁定类型 Tab、保存走 update）；记录簿长按改「编辑/删除」二选一菜单；猫咪详情健康时间线长按同样支持
- [x] **每日喂食提醒**：SettingsStore.feedReminderEnabled/feedReminderMinutes（默认 09:00）；Android matchDateTimeComponents.time 每日重复一次排定，Windows 预排未来 7 天一次性通知滚动覆盖；独立渠道 ecat_feed_reminders；设置页子开关 + 时间选择（总开关关闭时置灰）
- [x] **猫咪生日提醒**：每只猫「提前3天」+「当天」两条 09:00 通知；周年自动滚动（今年已过算明年）；2/29 生日平年落 2/28、闰年用 2/29；错过 0~1 天内补发去重
- [x] **测试通知手势修复**：设置页测试通知由长按改为点击触发（SwitchListTile 消费手势导致长按失效）
- [x] **测试**：新增 17 个单测（记录编辑 5 + 喂食提醒设置 2 + 生日周年计算 10），全量 27 测试全绿
- [ ] **喂食/生日提醒真实触发验证**：待用户在真机/桌面端实际等到触发时间验证（同 P3 通知伪验收口径）

### P6 — 全局触动反馈（2026-10-19 批次 `feat/p6-haptic-feedback` 已合并 v1.5.1 + v1.5.2）—— ✅ 已验收（2026-10-19，Android 真机）
- [x] **CuteTap 统一反馈组件**：按下轻微缩小（0.96）+ 触感震动（HapticFeedback.selectionClick），松手回弹；onTap/onLongPress 双支持，禁用态不拦截手势
- [x] **中心组件接入**：PawButton / CuteCard / CatAvatar / ViewCatTags / ChipChoice 全部走 CuteTap
- [x] **页面裸 GestureDetector 清零**：首页记一笔/空态、猫咪页顶栏入口/卡片/表单胶囊/日期行/返回键/健康时间线/历史体重、快捷记录日期行、记录簿长按、设置页测试通知、备份/统计返回键
- [x] **主题层 Material 反馈**：粉色水波纹 + InkSparkle 扩散，覆盖 TextButton/ListTile/Switch/FAB/NavigationBar
- [x] **底栏与记一笔补反馈（v1.5.2）**：NavigationBar 换自绘 CuteNav（每项按下放大 1.08 + 震动，选中态粉色胶囊）；FAB 换 PawButton（自带按压缩放 + 震动）—— Material 组件内部手势不透出，包 CuteTap 无效，必须自绘/替换
- [x] **测试**：新增 6 个组件单测（CuteTap 4 + CuteNav 2），全量 33 测试全绿

### 迁移手机端（随 P4 推进）
- [x] Android 真机安装验收（v1.5.2 APK，2026-10-19 通过）
- [ ] 键盘遮挡/小屏适配回归（弹窗已用 viewInsets 处理，理论无碍）
- [ ] iOS 需 macOS + Xcode（当前无此环境，暂缓）

## 八、开发方式记录

本项目采用**总驱动 + 子 agent 并行**模式开发：
- 总驱动完成基础层（模型/存储/主题/组件/骨架）固化公共契约
- 4 个子 agent 并行开发四个页面（各自只写自己的文件，接口靠基础层约束）
- 总驱动合并、统一修复 lint、编译验证

后续优化可沿用此模式：基础层改动由总驱动做，页面级改动可再派子 agent。

## 九、版本管理（2026-10-18 接入）

遵循 `版本管理规范/`（批次制迭代 + SemVer + Conventional Commits），版本记录见根目录 `VERSIONING.md`。

- v1.0.0 基线已入库（tag `v1.0.0`）
- v1.5.2 已发布（tag `v1.5.2`）：P6 全局触动反馈批次合并并真机验收通过；v1.5.0 的喂食/生日提醒仍待真实触发验证（同 P3 通知伪验收口径）
