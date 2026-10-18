// eCAT 通用可爱组件库
library;

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
