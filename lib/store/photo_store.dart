// eCAT · 照片头像存储服务
// 把用户选的照片复制进应用数据目录（不依赖原路径，避免源文件移动/删除后头像失效）。
// 文件名用猫咪 id + 时间戳，避免多猫/多次设置互相覆盖。
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoStore {
  PhotoStore._();

  /// 照片目录：应用支持目录下的 cat_photos 子目录
  /// Windows: `%APPDATA%\com.lvproject\ecat\cat_photos`
  /// Android: `/data/data/<pkg>/app_flutter/cat_photos`
  static Future<Directory> photoDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'cat_photos'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// 保存照片：复制进照片目录，返回新文件名（仅文件名，不含路径）
  static Future<String> saveFrom(String sourcePath, String catId) async {
    final dir = await photoDir();
    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp')
        ? ext
        : '.png';
    final name = 'cat_${catId}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    await File(sourcePath).copy(p.join(dir.path, name));
    return name;
  }

  /// 删除照片（按文件名）；文件不存在时静默忽略
  static Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      final dir = await photoDir();
      final f = File(p.join(dir.path, fileName));
      if (f.existsSync()) await f.delete();
    } catch (_) {
      // 删除失败不阻塞主流程
    }
  }

  /// 文件名 → 完整路径（文件不存在返回 null）
  static Future<String?> resolve(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    try {
      final dir = await photoDir();
      final f = File(p.join(dir.path, fileName));
      return f.existsSync() ? f.path : null;
    } catch (_) {
      return null;
    }
  }
}
