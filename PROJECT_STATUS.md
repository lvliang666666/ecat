# eCAT · 喵喵管家 — 项目进度文档

> 更新时间：2026-10-18
> 当前状态：**Windows 桌面端 v1.1 功能完成（P1 打磨批次已实现，待验收合并）**

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
| 状态管理 | provider 6.x（`CatStore extends ChangeNotifier`） |
| 本地存储 | shared_preferences 2.5（JSON 序列化） |
| 图表 | fl_chart 1.2.0（体重曲线） |
| 日期 | intl 0.20（zh_CN） |
| 平台 | Windows（已编译）+ Android（工程已就绪，待测试） |

## 三、目录结构

```
eCAT/
├── lib/
│   ├── main.dart              # App 入口 + 底部四 Tab 骨架 + CatSwitcher 切换器
│   ├── models/cat.dart        # Cat / FeedLog / WeightLog / HealthLog 数据模型
│   ├── store/cat_store.dart   # 全局状态：多猫管理、catId 隔离查询、持久化
│   ├── theme/app_theme.dart   # 可爱主题（AppColors + ThemeData）
│   ├── widgets/common.dart    # CuteCard / PawButton / CatAvatar / ChipChoice /
│   │                          # EmptyState / SectionTitle / showCuteSheet / showCuteToast
│   └── pages/
│       ├── home_page.dart     # Tab1「今天」：问候、档案卡、喂食进度、健康倒计时
│       ├── record_page.dart   # Tab2「记录」：合并时间线 + 筛选 + 长按删除
│       ├── cat_page.dart      # Tab3「猫咪」：多猫管理 + 表单 + 详情(体重曲线/健康时间线)
│       ├── knowledge_page.dart# Tab4「知识」：禁食红黑榜/疫苗表/健康自查/新手清单
│       └── quick_record.dart  # 快捷记录弹窗（喂食/体重/健康三合一，FAB 共用）
└── test/widget_test.dart      # 启动冒烟测试
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

### P2 — 数据服务
- [ ] **数据备份导出/导入**：JSON 文件导出导入，迁移手机端时直接带走数据
- [ ] **统计面板**：周/月喂食量统计、体重周报（「这周胖了 0.2kg 🎉」）
- [ ] **照片头像**：除 emoji 外支持本地照片（需 image_picker，注意跨端权限）

### P3 — 提醒与体验
- [ ] **本地提醒通知**：疫苗/驱虫到期系统通知（Windows 用 flutter_local_notifications 或 schedule_notif；Android 同插件）
- [ ] **首次引导页**：3 页 onboarding
- [ ] **深色模式**：奶油白主题夜间版

### 迁移手机端（打磨完成后）
- [ ] Android 真机 `flutter run` 测试（USB 调试）
- [ ] 键盘遮挡/小屏适配回归（弹窗已用 viewInsets 处理，理论无碍）
- [ ] `flutter build apk` 出安装包
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
- 当前批次分支 `feat/p1-polish`：喂食目标个性化 + 打卡动效 + App 图标，验证全绿待验收合并（预计 v1.1.0）
