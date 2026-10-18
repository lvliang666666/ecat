# eCAT · 经验教训库

> 记录开发过程中踩过的坑与解决方案，供后续开发复用。
> 每条经验包含：现象 → 根因 → 解决 → 预防。

---

## 1. Android 端 R8 混淆导致启动黑屏（2026-10-18，v1.3.0）

### 现象

- Windows 端一切正常，Android 端安装 APK 后**启动即黑屏**，无崩溃弹窗
- 进程实际存活（`pidof` 有 PID），但界面永远黑着
- `adb logcat` 中可见 `E/flutter` 未处理异常

### 根因（两层，逐层暴露）

**第一层：R8 重命名方法签名中的参数类型**

本项目使用的 Flutter 版本（3.44.9）**默认开启 R8 混淆**
（`FlutterPlugin.kt` 中 `releaseBuildType.isMinifyEnabled = true`，
可用 `shrink=false` 属性关闭）。

`shared_preferences` 插件新版走 **JNI 直接桥接**（pigeon native interop）：
Dart 侧通过 `package:jni` 用「类名 + 完整方法签名」调用 Java/Kotlin 方法：

```
getAll(Ljava/lang/String;Ljava/util/List;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;
```

R8 把 `kotlin.coroutines.Continuation` 重命名为 `w1.c`，
Dart 侧写死的签名在运行时找不到方法 → `NoSuchMethodError` →
启动时 `store.load()` 抛异常 → 界面卡死黑屏。

**第二层：R8 剥离整个类**

补上 `Continuation` 的 keep 规则后，又暴露第二层：
jni 包的 Dart 侧还按类名引用了
`kotlin/coroutines/intrinsics/CoroutineSingletons`、`IntrinsicsKt`、
`kotlin/Result`、`kotlin/Unit` 等，R8 把它们**整个剥离/重命名** →
`ClassNotFoundException`。

### 解决

`android/app/proguard-rules.pro`（已提交）：

```proguard
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
```

并在 `android/app/build.gradle.kts` 的 release buildType 挂载该文件。

### 排查方法论（复用价值最高）

1. **黑屏 ≠ 崩溃**：先 `adb shell pidof <pkg>` 判断进程是否存活
2. **抓真因**：`adb logcat -c` 清缓冲 → 启动 app → `adb logcat -d | grep "E/flutter"`
3. **验证混淆假设**：解包 APK 用 `dexdump` 查类名/方法签名，
   对照 `build/app/outputs/mapping/release/mapping.txt`（R8 映射表）
   确认「Dart 侧引用的名字」与「APK 里实际的名字」是否一致
4. **修复验证**：重新构建后 grep mapping.txt 确认目标类不再被重命名

### 预防

- 以后新增任何**通过 JNI/pigeon native interop 调用原生代码的插件**
  （尤其 Kotlin suspend 方法），都要检查 R8 keep 规则
- Android 端每次发版前，**必须真机冷启动验证**，不能只看构建成功
- 遇到「Windows 正常、Android 黑屏」优先怀疑 R8 混淆

---

## 2. Windows 构建失败 LNK1104（反复出现）

### 现象

`flutter build windows --release` 报
`LNK1104: 无法打开文件 ecat.exe`。

### 根因

ecat.exe 正在运行（用户验收时打开着），链接器无法覆盖。

### 解决 / 预防

构建前先确认进程已退出：

```bash
tasklist //FI "IMAGENAME eq ecat.exe"
```

**发版流程固定为：请用户关闭 app → 确认进程不在 → 再构建。**

---

## 3. Kotlin 增量编译缓存损坏（Windows + Gradle 9 + Kotlin 2.3）

### 现象

`flutter build apk --release` 失败，报
`Could not close incremental caches ... class-fq-name-to-source.tab`
（多个插件并发报同样错误），且清单个插件缓存后复发。

### 根因

Windows 下 Kotlin 守护进程持有旧缓存文件句柄，
多插件并发编译时缓存注册冲突（`Storage ... is already registered`）。

### 解决（已固化到 `android/gradle.properties`）

```properties
kotlin.compiler.execution.strategy=in-process
kotlin.incremental=false
```

必要时配合 `./gradlew --stop` 停守护进程 + 删除
`build/<插件名>/kotlin` 缓存目录。

---

## 4. Gradle 依赖下载超时（国内网络）

### 现象

首次构建 Android 端时 Gradle 拉取依赖失败
（`Gradle threw an error while downloading artifacts`）。

### 解决（已固化到 `android/settings.gradle.kts` 与 `android/build.gradle.kts`）

阿里云 Maven 镜像放在官方源之前（失败自动回退）：

```kotlin
maven("https://maven.aliyun.com/repository/google")
maven("https://maven.aliyun.com/repository/central")
google()
mavenCentral()
```

注意：`pubspec.lock` 会在 `pub get` 时把镜像 URL 在
pub.dev / pub.flutter-io.cn 之间翻转，**提交前用
`git checkout -- pubspec.lock` 还原**，保持提交干净。

---

## 5. exe 时间戳 ≠ 构建成功（Windows 构建产物结构）

### 现象

重新构建后 `ecat.exe` 时间戳没变，误以为构建没生效。

### 根因

Windows release 产物中，`ecat.exe` 只是 ~55KB 的启动器，
**Dart 代码在 `data/app.so`**。代码没变时 exe 不变是正常的。

### 预防

验证构建产物新鲜度看 `data/app.so` 的时间戳；
怀疑缓存问题时 `flutter clean` 后全量重建。

---

## 6. image_picker 在 Windows 是 dart-only 插件

### 现象

`image_picker_windows` 不出现在
`windows/flutter/generated_plugins.cmake`，怀疑没编译进去。

### 根因

它是 **dart-only 联合插件**（dartPluginClass 委托给
file_selector_windows），不需要原生注册，属正常现象。

### 预防

排查插件加载问题时先分清 native 插件（要进 generated_plugins）
和 dart-only 插件（不进）。

---

## 7. 用户验收习惯与协作约定

- **验收方式**：Windows 端直接双击
  `build\windows\x64\runner\Release\ecat.exe`；Android 端装 APK 真机点开
- **构建前必须确认 exe 未运行**（见经验 2）
- **APK 产物**：复制到项目根目录并带版本号命名
  （如 `ecat-v1.3.0-android.apk`），已加入 .gitignore
- **vivo 手机 adb 安装**：无线 adb 连接会出现两条重复设备记录，
  操作时用 `-s <transport_id 对应的序列>` 指定设备；
  `adb install` 会弹手机端确认框，**需要用户在手机上点允许**，
  被拒绝时报 `INSTALL_FAILED_ABORTED: User rejected permissions`
- **用户偏好**：不要用结构化提问工具反复确认方向，
  用户会用文字直接说明需求；理解需求后直接开工
