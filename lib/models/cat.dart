// eCAT 数据模型层
// 以猫咪为中心：每只猫拥有独立档案，所有记录通过 catId 挂载，
// 实现「一猫一档、数据隔离、个性化服务」。
library;

import 'dart:convert';

/// 猫咪档案
class Cat {
  final String id;
  String name; // 名字
  String breed; // 品种
  DateTime birthday; // 生日
  String gender; // genderBoy / genderGirl
  bool neutered; // 是否绝育
  String furColor; // 毛色
  String avatar; // emoji 头像
  double? targetWeight; // 目标体重 kg
  double dailyFoodGoal; // 每日喂食目标 g（饮水不计入）
  List<String> allergies; // 过敏/禁忌
  String notes; // 备注（性格、习惯、病史）

  Cat({
    required this.id,
    required this.name,
    this.breed = '田园猫',
    required this.birthday,
    this.gender = genderGirl,
    this.neutered = false,
    this.furColor = '橘色',
    this.avatar = '🐱',
    this.targetWeight,
    double? dailyFoodGoal,
    List<String>? allergies,
    this.notes = '',
  })  : dailyFoodGoal = (dailyFoodGoal == null || dailyFoodGoal <= 0)
            ? defaultDailyFoodGoal
            : dailyFoodGoal,
        allergies = allergies ?? [];

  static const String genderBoy = '弟弟';
  static const String genderGirl = '妹妹';

  /// 每日喂食目标默认值（g）
  static const double defaultDailyFoodGoal = 60;

  /// 猫龄描述，如「2岁3个月」
  String ageText([DateTime? now]) {
    final n = now ?? DateTime.now();
    int months = (n.year - birthday.year) * 12 + n.month - birthday.month;
    if (n.day < birthday.day) months--;
    if (months < 0) months = 0;
    final y = months ~/ 12;
    final m = months % 12;
    if (y <= 0) return '$m个月';
    if (m == 0) return '$y岁';
    return '$y岁$m个月';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'breed': breed,
        'birthday': birthday.toIso8601String(),
        'gender': gender,
        'neutered': neutered,
        'furColor': furColor,
        'avatar': avatar,
        'targetWeight': targetWeight,
        'dailyFoodGoal': dailyFoodGoal,
        'allergies': allergies,
        'notes': notes,
      };

  factory Cat.fromJson(Map<String, dynamic> j) => Cat(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        breed: (j['breed'] ?? '田园猫') as String,
        birthday: DateTime.parse(j['birthday'] as String),
        gender: (j['gender'] ?? genderGirl) as String,
        neutered: (j['neutered'] ?? false) as bool,
        furColor: (j['furColor'] ?? '') as String,
        avatar: (j['avatar'] ?? '🐱') as String,
        targetWeight: (j['targetWeight'] as num?)?.toDouble(),
        dailyFoodGoal: (j['dailyFoodGoal'] as num?)?.toDouble(),
        allergies: ((j['allergies'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        notes: (j['notes'] ?? '') as String,
      );

  String encode() => jsonEncode(toJson());

  static Cat decode(String s) => Cat.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// 喂食记录
class FeedLog {
  final String id;
  final String catId;
  final DateTime time;
  final String type; // 干粮 / 湿粮罐头 / 冻干 / 零食 / 饮水
  final double amount; // 数量（g 或 ml）
  final String note;

  FeedLog({
    required this.id,
    required this.catId,
    required this.time,
    required this.type,
    required this.amount,
    this.note = '',
  });

  static const List<String> types = ['干粮', '湿粮罐头', '冻干', '零食', '饮水'];

  Map<String, dynamic> toJson() => {
        'id': id, 'catId': catId, 'time': time.toIso8601String(),
        'type': type, 'amount': amount, 'note': note,
      };

  factory FeedLog.fromJson(Map<String, dynamic> j) => FeedLog(
        id: j['id'] as String,
        catId: j['catId'] as String,
        time: DateTime.parse(j['time'] as String),
        type: (j['type'] ?? '干粮') as String,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        note: (j['note'] ?? '') as String,
      );
}

/// 体重记录
class WeightLog {
  final String id;
  final String catId;
  final DateTime date;
  final double weight; // kg

  WeightLog({
    required this.id,
    required this.catId,
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'catId': catId, 'date': date.toIso8601String(), 'weight': weight,
      };

  factory WeightLog.fromJson(Map<String, dynamic> j) => WeightLog(
        id: j['id'] as String,
        catId: j['catId'] as String,
        date: DateTime.parse(j['date'] as String),
        weight: (j['weight'] as num).toDouble(),
      );
}

/// 健康记录：疫苗 / 驱虫 / 洗澡 / 就医 / 症状
class HealthLog {
  final String id;
  final String catId;
  final DateTime date;
  final String category; // vaccine / deworm / bath / doctor / symptom
  final String title; // 如「猫三联第二针」「体内驱虫」
  final String note;
  final DateTime? nextDue; // 下次到期时间（用于倒计时提醒）

  HealthLog({
    required this.id,
    required this.catId,
    required this.date,
    required this.category,
    required this.title,
    this.note = '',
    this.nextDue,
  });

  static const Map<String, String> categories = {
    'vaccine': '疫苗',
    'deworm': '驱虫',
    'bath': '洗澡',
    'doctor': '就医',
    'symptom': '症状',
  };

  static const Map<String, String> categoryEmoji = {
    'vaccine': '💉', 'deworm': '🐛', 'bath': '🛁', 'doctor': '🏥', 'symptom': '🤒',
  };

  Map<String, dynamic> toJson() => {
        'id': id, 'catId': catId, 'date': date.toIso8601String(),
        'category': category, 'title': title, 'note': note,
        'nextDue': nextDue?.toIso8601String(),
      };

  factory HealthLog.fromJson(Map<String, dynamic> j) => HealthLog(
        id: j['id'] as String,
        catId: j['catId'] as String,
        date: DateTime.parse(j['date'] as String),
        category: (j['category'] ?? 'symptom') as String,
        title: (j['title'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        nextDue: j['nextDue'] == null ? null : DateTime.parse(j['nextDue'] as String),
      );
}
