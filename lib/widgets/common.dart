// eCAT 通用可爱组件库
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 大圆角软阴影卡片
class CuteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final VoidCallback? onTap;

  const CuteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color = AppColors.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

/// 猫爪胶囊按钮（主操作）
class PawButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final bool expanded;

  const PawButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.pink,
    this.textColor = Colors.white,
    this.icon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: onTap == null ? AppColors.textSub.withValues(alpha: 0.4) : color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: onTap == null
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    final gesture = GestureDetector(
      onTap: onTap,
      child: btn,
    );
    return expanded ? SizedBox(width: double.infinity, child: gesture) : gesture;
  }
}

/// 猫咪 emoji 头像（带渐变底）
class CatAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final VoidCallback? onTap;

  const CatAvatar({super.key, required this.emoji, this.size = 56, this.onTap});

  @override
  Widget build(BuildContext context) {
    final av = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pinkLight, AppColors.butter],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
    );
    if (onTap == null) return av;
    return GestureDetector(onTap: onTap, child: av);
  }
}

/// 可选胶囊（大按钮点选交互，用于类型选择）
class ChipChoice<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelect;
  final Map<T, String>? labels;
  final Map<T, String>? emojis;

  const ChipChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelect,
    this.labels,
    this.emojis,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((v) {
        final sel = v == selected;
        final label = labels?[v] ?? v.toString();
        final emoji = emojis?[v];
        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.pink : AppColors.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? AppColors.pinkDeep : AppColors.pinkLight,
                width: sel ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.textMain,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 空状态（可爱猫爪 + 提示文案）
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.emoji = '🐾',
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 区块标题（左侧猫爪点缀）
class SectionTitle extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.emoji = '🐾',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// 底部弹窗容器（统一圆角 + 拖动条）
Future<T?> showCuteSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        // 限制弹窗最大高度为屏幕的 90%，超出部分由内部 SingleChildScrollView 滚动，
        // 避免长表单（如添加猫咪）溢出屏幕导致按钮不可见。
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.pinkLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Flexible(child: builder(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 轻提示
void showCuteToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: AppColors.pinkDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(milliseconds: 1500),
    ),
  );
}

/// 打卡成功庆祝动画：中央猫爪印弹跳 + 四周彩色粒子扩散，约 1.2s 后自动消失。
/// 用于喂食/体重/健康/档案保存成功后的可爱反馈，不阻挡操作（忽略指针）。
void showPawCelebration(BuildContext context, {String emoji = '🐾'}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PawCelebrationOverlay(
      emoji: emoji,
      onFinished: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

/// 庆祝动画的 Overlay 内容：透明全屏 + 居中动画
class _PawCelebrationOverlay extends StatefulWidget {
  final String emoji;
  final VoidCallback onFinished;

  const _PawCelebrationOverlay({required this.emoji, required this.onFinished});

  @override
  State<_PawCelebrationOverlay> createState() => _PawCelebrationOverlayState();
}

class _PawCelebrationOverlayState extends State<_PawCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished();
    });
    // 固定随机种子保证粒子形态稳定，颜色从主题色系中取
    final rng = math.Random(7);
    final colors = [
      AppColors.pink,
      AppColors.pinkDeep,
      AppColors.butterDeep,
      AppColors.mintDeep,
      AppColors.skyDeep,
    ];
    _particles = List.generate(10, (i) {
      final angle = rng.nextDouble() * math.pi * 2; // 均匀散开的方向
      final dist = 90 + rng.nextDouble() * 70; // 扩散距离 90~160
      return _Particle(
        angle: angle,
        distance: dist,
        size: 6 + rng.nextDouble() * 6,
        color: colors[i % colors.length],
        delay: rng.nextDouble() * 0.15, // 轻微错峰出发
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // 中央猫爪印：0~0.35 弹跳放大，0.65 后淡出
                if (t < 0.8)
                  Transform.scale(
                    scale: _pawScale(t),
                    child: Opacity(
                      opacity: t < 0.6 ? 1 : 1 - (t - 0.6) / 0.2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pink.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                  ),
                // 彩色粒子：从中心向外扩散并淡出
                for (final p in _particles) _buildParticle(p, t),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 爪印缩放曲线：先过冲弹到 1.25，再回落到 1.0
  double _pawScale(double t) {
    if (t < 0.35) {
      final k = t / 0.35;
      // easeOutBack：轻微过冲的弹性放大
      final c = 2.6;
      final v = 1 + (c + 1) * math.pow(k - 1, 3) + c * math.pow(k - 1, 2);
      return 0.4 + 0.85 * v.clamp(0.0, 1.4);
    }
    return 1.0;
  }

  /// 单个粒子：按全局进度计算位置与透明度
  Widget _buildParticle(_Particle p, double t) {
    // 粒子在 0.1~0.9 区间运动，带各自 delay
    final local = ((t - 0.1 - p.delay) / 0.65).clamp(0.0, 1.0);
    if (local <= 0) return const SizedBox.shrink();
    final dist = p.distance * Curves.easeOutCubic.transform(local);
    final opacity = 1 - local;
    return Transform.translate(
      offset: Offset(
        math.cos(p.angle) * dist,
        math.sin(p.angle) * dist,
      ),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            color: p.color,
            shape: p.size > 8 ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                p.size > 8 ? null : BorderRadius.circular(p.size * 0.35),
          ),
        ),
      ),
    );
  }
}

/// 粒子参数：方向角 / 扩散距离 / 尺寸 / 颜色 / 出发延迟
class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double delay;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.delay,
  });
}
