// 养猫百科页（知识 Tab）：禁食红黑榜 / 疫苗时间表 / 健康自查 / 新手清单
// 纯静态干货内容 + 本地勾选状态，不依赖 CatStore；由 main.dart 以 Scaffold.body 形式嵌入。
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 四个板块的 key（用于 ChipChoice 切换）
const String _kTabForbidden = 'forbidden';
const String _kTabVaccine = 'vaccine';
const String _kTabHealth = 'health';
const String _kTabChecklist = 'checklist';

/// 养猫知识页：新手铲屎官的干货手册
class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  /// 当前选中的板块
  String _tab = _kTabForbidden;

  /// 新手清单已勾选项（key 形如 'before-0' / 'after-1'），仅本地状态，不持久化
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            ChipChoice<String>(
              values: const [
                _kTabForbidden,
                _kTabVaccine,
                _kTabHealth,
                _kTabChecklist,
              ],
              selected: _tab,
              onSelect: (v) => setState(() => _tab = v),
              labels: const {
                _kTabForbidden: '禁食红黑榜',
                _kTabVaccine: '疫苗时间表',
                _kTabHealth: '健康自查',
                _kTabChecklist: '新手清单',
              },
              emojis: const {
                _kTabForbidden: '🚫',
                _kTabVaccine: '💉',
                _kTabHealth: '🩺',
                _kTabChecklist: '📋',
              },
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey<String>(_tab),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标题栏
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '养猫百科 📚',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '新手铲屎官的干货手册',
                style: TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
        ),
        const Text('🐾', style: TextStyle(fontSize: 26)),
      ],
    );
  }

  /// 按板块切换内容
  Widget _buildContent() {
    switch (_tab) {
      case _kTabVaccine:
        return _buildVaccine();
      case _kTabHealth:
        return _buildHealth();
      case _kTabChecklist:
        return _buildChecklist();
      default:
        return _buildForbidden();
    }
  }

  // ==================== 🚫 禁食红黑榜 ====================

  Widget _buildForbidden() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '绝对禁食',
          emoji: '🚫',
          trailing: _RiskBadge(text: '一口都不行！', color: AppColors.danger),
        ),
        ..._forbiddenFoods.map(
          (e) => _FoodCard(
            item: e,
            barColor: AppColors.danger,
            bgColor: AppColors.danger.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle(
          title: '谨慎少量',
          emoji: '⚠️',
          trailing: _RiskBadge(text: '遵医嘱', color: AppColors.butterDeep),
        ),
        ..._cautionFoods.map(
          (e) => _FoodCard(
            item: e,
            barColor: AppColors.butterDeep,
            bgColor: AppColors.butter.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle(
          title: '安全放心',
          emoji: '✅',
          trailing: _RiskBadge(text: '放心喂', color: AppColors.mintDeep),
        ),
        ..._safeFoods.map(
          (e) => _FoodCard(
            item: e,
            barColor: AppColors.mintDeep,
            bgColor: AppColors.mint.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ==================== 💉 疫苗时间表 ====================

  Widget _buildVaccine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '免疫时间线',
          emoji: '💉',
          trailing: _RiskBadge(text: '按时接种', color: AppColors.pinkDeep),
        ),
        for (int i = 0; i < _vaccineSchedule.length; i++)
          _TimelineTile(
            item: _vaccineSchedule[i],
            isLast: i == _vaccineSchedule.length - 1,
          ),
        const SizedBox(height: 8),
        const SectionTitle(title: '驱虫别忘记', emoji: '🐛'),
        CuteCard(
          color: AppColors.butter.withValues(alpha: 0.55),
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dewormRow('体内驱虫', '每 3 个月 1 次'),
              const SizedBox(height: 8),
              _dewormRow('体外驱虫', '每月 1 次（外出的、门窗常开家庭更要坚持）'),
            ],
          ),
        ),
      ],
    );
  }

  /// 驱虫补充卡里的一行
  Widget _dewormRow(String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.butterDeep.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMain,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 🩺 健康自查 ====================

  Widget _buildHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: '常见症状速查',
          emoji: '🩺',
          trailing: _RiskBadge(text: '对症观察', color: AppColors.skyDeep),
        ),
        ..._symptoms.map(_symptomCard),
        const SizedBox(height: 8),
        // 底部就医提示卡
        CuteCard(
          color: AppColors.butter.withValues(alpha: 0.55),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '以上仅供参考，猫咪异常持续请及时就医，就医时可出示 App 里的健康记录 🐾',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMain,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 症状卡：症状 + 可能原因 + 行动建议
  Widget _symptomCard(_SymptomItem s) {
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.symptom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSub,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: '可能原因：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: s.cause),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👉', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.action,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMain,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 📋 新手清单 ====================

  Widget _buildChecklist() {
    final total = _checklistBefore.length + _checklistAfter.length;
    final done = _checked.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度卡
        CuteCard(
          color: AppColors.pinkLight.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '📋 备货进度',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '已完成 $done/$total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: done == total
                          ? AppColors.mintDeep
                          : AppColors.pinkDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: done / total,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: AppColors.pink,
                ),
              ),
              if (done == total) ...[
                const SizedBox(height: 8),
                const Text(
                  '全部备齐，可以接猫咪回家啦 🎉',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mintDeep,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SectionTitle(title: '接猫前', emoji: '🧳'),
        ...List.generate(
          _checklistBefore.length,
          (i) => _checkRow('before', i, _checklistBefore[i]),
        ),
        const SizedBox(height: 8),
        const SectionTitle(title: '接猫后', emoji: '🏠'),
        ...List.generate(
          _checklistAfter.length,
          (i) => _checkRow('after', i, _checklistAfter[i]),
        ),
      ],
    );
  }

  /// 可勾选的清单条目
  Widget _checkRow(String group, int index, String text) {
    final key = '$group-$index';
    final checked = _checked.contains(key);
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => setState(() {
        if (_checked.contains(key)) {
          _checked.remove(key);
        } else {
          _checked.add(key);
        }
      }),
      child: Row(
        children: [
          _checkbox(checked),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: checked ? AppColors.textSub : AppColors.textMain,
                fontWeight: checked ? FontWeight.w400 : FontWeight.w500,
                decoration: checked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 可爱圆形 checkbox
  Widget _checkbox(bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.pink : Colors.white,
        border: Border.all(
          color: checked ? AppColors.pinkDeep : AppColors.pinkLight,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

// ==================== 页面内部小部件 ====================

/// 红黑榜分组小徽章
class _RiskBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RiskBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// 禁食红黑榜条目卡：左侧色条 + emoji + 名称 + 一句话原因
class _FoodCard extends StatelessWidget {
  final _FoodItem item;
  final Color barColor;
  final Color bgColor;

  const _FoodCard({
    required this.item,
    required this.barColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CuteCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: bgColor,
      child: Row(
        children: [
          Container(
            width: 5,
            height: 38,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(item.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 疫苗时间线卡片：左侧圆点 + 连接线，右侧内容卡
class _TimelineTile extends StatelessWidget {
  final _VaccineItem item;
  final bool isLast;

  const _TimelineTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pink,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 3,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isLast ? Colors.transparent : AppColors.pinkLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CuteCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pinkLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.age,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pinkDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMain,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 干货内容数据（const，集中定义在文件底部） ====================

/// 禁食红黑榜条目
class _FoodItem {
  final String emoji;
  final String name;
  final String reason;
  const _FoodItem(this.emoji, this.name, this.reason);
}

/// 绝对禁食（危险）
const List<_FoodItem> _forbiddenFoods = [
  _FoodItem('🍫', '巧克力', '含可可碱，猫代谢极慢，中毒可致命'),
  _FoodItem('🧅', '洋葱 / 大蒜', '破坏红细胞导致溶血性贫血，葱蒜类全都不行'),
  _FoodItem('🍇', '葡萄 / 葡萄干', '可能引发急性肾衰竭，少量也危险'),
  _FoodItem('🌸', '百合花', '全株剧毒，花粉沾到毛上舔进嘴也会肾衰'),
  _FoodItem('🍺', '酒精', '极少量即可损伤大脑和肝脏'),
  _FoodItem('☕', '咖啡 / 咖啡因', '咖啡因中毒，引起心跳加速、抽搐'),
  _FoodItem('🍬', '木糖醇', '导致胰岛素骤降、低血糖甚至肝损伤'),
  _FoodItem('🥖', '生面团', '在胃里发酵产气产酒精，腹胀又中毒'),
];

/// 谨慎少量 / 遵医嘱
const List<_FoodItem> _cautionFoods = [
  _FoodItem('🥛', '牛奶', '多数猫乳糖不耐受易腹泻，建议换羊奶'),
  _FoodItem('🐟', '生鱼', '含硫胺素酶破坏维生素B1，务必煮熟'),
  _FoodItem('🥫', '金枪鱼罐头', '营养不均且汞含量偏高，只能当零食'),
  _FoodItem('🍚', '人类剩菜', '油盐调料远超猫的代谢能力'),
];

/// 安全放心
const List<_FoodItem> _safeFoods = [
  _FoodItem('🍗', '鸡胸肉', '煮熟撕小块，优质蛋白加餐'),
  _FoodItem('🎃', '南瓜', '蒸熟少量，膳食纤维帮助排出毛球'),
  _FoodItem('🐐', '羊奶', '乳糖含量低，比牛奶更适合猫'),
  _FoodItem('🌿', '猫草', '催吐毛球、缓解肠胃不适'),
  _FoodItem('🥚', '蛋黄', '煮熟后少量喂，补充卵磷脂'),
];

/// 疫苗时间线条目
class _VaccineItem {
  final String emoji;
  final String age;
  final String content;
  const _VaccineItem(this.emoji, this.age, this.content);
}

/// 免疫时间线
const List<_VaccineItem> _vaccineSchedule = [
  _VaccineItem('💉', '2 月龄', '猫三联第 1 针（预防泛白细胞减少症 / 杯状病毒 / 疱疹病毒）'),
  _VaccineItem('💉', '3 月龄', '猫三联第 2 针，与第 1 针间隔 3~4 周'),
  _VaccineItem('💉', '4 月龄', '猫三联第 3 针 + 狂犬疫苗（狂犬之后每年 1 针）'),
  _VaccineItem('📅', '之后每年', '猫三联加强 1 针 + 狂犬疫苗 1 针，按时年免'),
];

/// 健康自查症状条目
class _SymptomItem {
  final String emoji;
  final String symptom;
  final String cause;
  final String action;
  const _SymptomItem(this.emoji, this.symptom, this.cause, this.action);
}

/// 常见症状速查
const List<_SymptomItem> _symptoms = [
  _SymptomItem('💩', '软便 / 腹泻', '换粮太快、寄生虫、应激', '观察精神食欲，超过 2 天或带血请就医'),
  _SymptomItem('🤮', '频繁呕吐', '毛球、吃太快、误食异物', '一周 1~2 次属正常，频繁或带黄水请就医'),
  _SymptomItem('🤧', '打喷嚏 / 流涕', '感冒、猫鼻支（疱疹病毒）', '观察体温和眼睛分泌物，幼猫尽快就医'),
  _SymptomItem('👂', '频繁挠耳', '耳螨感染', '检查耳道有无黑褐色分泌物，坚持用洗耳液清理'),
  _SymptomItem('🚰', '多饮多尿', '糖尿病 / 肾病的早期信号', '记录每天饮水量，尽快就医检查'),
  _SymptomItem('⚖️', '体重骤降', '寄生虫、甲亢、糖尿病', '记录体重曲线，尽快就医排查'),
];

/// 新手清单：接猫前
const List<String> _checklistBefore = [
  '食盆 + 水盆（分开放置）',
  '猫粮（先问清原粮食，避免应激）',
  '猫砂盆 + 猫砂',
  '航空箱 / 猫包',
  '指甲剪',
];

/// 新手清单：接猫后
const List<String> _checklistAfter = [
  '7 天过渡粮（新旧粮逐步混合）',
  '体检 + 疫苗咨询',
  '封窗！高层家庭必做 ⚠️',
  '收好电线和小物件，防误食',
  '准备猫抓板，拯救沙发',
];
