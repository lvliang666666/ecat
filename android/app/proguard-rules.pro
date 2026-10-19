# eCAT Android R8 keep 规则
#
# 背景：jni 包（package:jni）在 Dart 侧用「类名 + 完整方法签名」通过
# JNI GetMethodID 查找 Kotlin suspend 方法（如 shared_preferences_android
# 的 SharedPreferencesApiRegistrar.getAll）。R8 混淆会把
# kotlin.coroutines.Continuation 重命名为 w1.c，导致 Dart 侧写死的签名
# `(...Lkotlin/coroutines/Continuation;)...` 找不到方法，运行时抛
# NoSuchMethodError，应用启动即黑屏。
#
# 因此：所有被 Dart 侧 JNI 桥接（pigeon native interop）调用的 Kotlin
# suspend 方法及其参数类型必须保持原名。

# 1) kotlin.coroutines 协程基础类型：jni 包（package:jni）的 Dart 侧
#    通过 JClass.forName 按原名引用以下类（Continuation / CoroutineSingletons /
#    IntrinsicsKt / Result / Unit 等），R8 重命名或剥离任何一个都会导致
#    ClassNotFoundException / NoSuchMethodError
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }

# 2) jni 包自身的运行时类（PortContinuation / PortProxy 等）
-keep class com.github.dart_lang.jni.** { *; }

# 3) 插件的 Pigeon 生成类：Dart 侧按原名 + 原签名查找
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# 4) flutter_local_notifications（v1.4.0 接入）：
#    Android 端是纯 MethodChannel 插件（无 JNI 桥接，不踩经验 1 的坑），
#    但其定时通知链路有两处反射/隐式引用，R8 破坏后症状是「定时通知静默失效」：
#    a) Gson 反射序列化：NotificationDetails 等模型字段名即 JSON key，
#       混淆后 fromJson 填不进字段 → 到期不弹通知
#    b) ScheduledNotificationReceiver / BootReceiver 由 AlarmManager 的
#       PendingIntent 广播触发（manifest 里动态注册），剥离即失效
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
