// CatStore 记录编辑方法单元测试：updateFeed / updateWeight / updateHealth
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecat/models/cat.dart';
import 'package:ecat/store/cat_store.dart';

Cat _cat(String id) => Cat(
      id: id,
      name: '咪咪',
      birthday: DateTime(2023, 5, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatStore 记录编辑', () {
    test('updateFeed 按 id 替换内容', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CatStore();
      await store.load();
      await store.addCat(_cat('c1'));

      final log = FeedLog(
        id: 'f1',
        catId: 'c1',
        time: DateTime(2026, 10, 19, 9),
        type: '干粮',
        amount: 30,
      );
      await store.addFeed(log);

      await store.updateFeed(FeedLog(
        id: 'f1',
        catId: 'c1',
        time: DateTime(2026, 10, 19, 10),
        type: '湿粮罐头',
        amount: 45,
        note: '加餐',
      ));

      expect(store.feeds.length, 1);
      expect(store.feeds.first.type, '湿粮罐头');
      expect(store.feeds.first.amount, 45);
      expect(store.feeds.first.note, '加餐');
    });

    test('updateWeight 改日期后同日去重仍生效', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CatStore();
      await store.load();
      await store.addCat(_cat('c1'));

      final d1 = DateTime(2026, 10, 1);
      final day2 = DateTime(2026, 10, 2);
      await store.addWeight(WeightLog(
          id: 'w1', catId: 'c1', date: d1, weight: 4.0));
      await store.addWeight(WeightLog(
          id: 'w2', catId: 'c1', date: day2, weight: 4.2));

      // 把 w1 改到 10/2 → 与 w2 同日，w2 应被替换掉
      await store.updateWeight(WeightLog(
          id: 'w1', catId: 'c1', date: day2, weight: 4.5));

      expect(store.weights.length, 1);
      expect(store.weights.first.id, 'w1');
      expect(store.weights.first.weight, 4.5);
    });

    test('updateWeight 不存在时退化为新增', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CatStore();
      await store.load();
      await store.addCat(_cat('c1'));

      await store.updateWeight(WeightLog(
          id: 'w-new', catId: 'c1', date: DateTime(2026, 10, 3), weight: 4.1));

      expect(store.weights.length, 1);
      expect(store.weights.first.id, 'w-new');
    });

    test('updateHealth 替换内容并持久化', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CatStore();
      await store.load();
      await store.addCat(_cat('c1'));

      await store.addHealth(HealthLog(
        id: 'h1',
        catId: 'c1',
        date: DateTime(2026, 10, 1),
        category: 'vaccine',
        title: '猫三联第一针',
        nextDue: DateTime(2026, 11, 1),
      ));

      await store.updateHealth(HealthLog(
        id: 'h1',
        catId: 'c1',
        date: DateTime(2026, 10, 1),
        category: 'vaccine',
        title: '猫三联第一针（已改）',
        nextDue: DateTime(2026, 11, 15),
      ));

      expect(store.healths.length, 1);
      expect(store.healths.first.title, '猫三联第一针（已改）');
      expect(store.healths.first.nextDue, DateTime(2026, 11, 15));

      // 重启模拟：新实例读回
      final store2 = CatStore();
      await store2.load();
      expect(store2.healths.first.title, '猫三联第一针（已改）');
    });

    test('update 不存在的 id 静默无副作用', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CatStore();
      await store.load();
      await store.addCat(_cat('c1'));

      await store.updateFeed(FeedLog(
          id: 'nope', catId: 'c1', time: DateTime.now(), type: '干粮', amount: 1));
      await store.updateHealth(HealthLog(
          id: 'nope', catId: 'c1', date: DateTime.now(), category: 'bath', title: 'x'));

      expect(store.feeds, isEmpty);
      expect(store.healths, isEmpty);
    });
  });
}
