// 生日提醒周年计算单测：nextBirthdayAt（含 2/29 闰年边界）
import 'package:flutter_test/flutter_test.dart';

import 'package:ecat/services/reminder_service.dart';

void main() {
  group('nextBirthdayAt 生日周年计算', () {
    test('今年生日未到 → 返回今年周年 09:00', () {
      final at = nextBirthdayAt(
        DateTime(2023, 5, 1),
        DateTime(2026, 10, 19),
        0,
      );
      expect(at, DateTime(2027, 5, 1, 9).subtract(const Duration(days: 0)));
      // 等价断言：2027-05-01 09:00（今年 5/1 已过 → 明年）
      expect(at!.year, 2027);
      expect(at.month, 5);
      expect(at.day, 1);
      expect(at.hour, 9);
    });

    test('今年生日还没到 → 返回今年', () {
      final at = nextBirthdayAt(
        DateTime(2023, 12, 25),
        DateTime(2026, 10, 19),
        0,
      );
      expect(at, DateTime(2026, 12, 25, 9));
    });

    test('提前3天：生日前3天内 → 返回提前提醒时刻', () {
      // 今天 10/16，生日 10/19 → 提前3天提醒就是今天 09:00
      final at = nextBirthdayAt(
        DateTime(2023, 10, 19),
        DateTime(2026, 10, 16),
        3,
      );
      expect(at, DateTime(2026, 10, 16, 9));
    });

    test('提前3天：已过提前窗口 → 滚动到明年', () {
      // 今天 10/17，生日 10/19 的提前3天提醒（10/16）已过 → 明年 10/16
      final at = nextBirthdayAt(
        DateTime(2023, 10, 19),
        DateTime(2026, 10, 17),
        3,
      );
      expect(at, DateTime(2027, 10, 16, 9));
    });

    test('2/29 生日：平年落到 2/28', () {
      // 2027 是平年（2027 % 4 != 0）
      final at = nextBirthdayAt(
        DateTime(2024, 2, 29),
        DateTime(2026, 10, 19),
        0,
      );
      // 今年（2026 平年）2/28 已过 → 明年 2027 平年 2/28
      expect(at, DateTime(2027, 2, 28, 9));
    });

    test('2/29 生日：闰年用 2/29', () {
      // 2028 是闰年
      final at = nextBirthdayAt(
        DateTime(2024, 2, 29),
        DateTime(2027, 10, 19),
        0,
      );
      // 2027 平年 2/28 已过 → 2028 闰年 2/29
      expect(at, DateTime(2028, 2, 29, 9));
    });

    test('生日当天 → 当天 09:00（offset=0 不滚动）', () {
      final at = nextBirthdayAt(
        DateTime(2023, 10, 19),
        DateTime(2026, 10, 19),
        0,
      );
      expect(at, DateTime(2026, 10, 19, 9));
    });

    test('生日当天提前3天提醒 → 已过，滚动到明年', () {
      final at = nextBirthdayAt(
        DateTime(2023, 10, 19),
        DateTime(2026, 10, 19),
        3,
      );
      expect(at, DateTime(2027, 10, 16, 9));
    });

    test('跨年边界：12/31 生日在 1/1 看 → 今年 12/31', () {
      final at = nextBirthdayAt(
        DateTime(2023, 12, 31),
        DateTime(2026, 1, 1),
        0,
      );
      expect(at, DateTime(2026, 12, 31, 9));
    });

    test('1/1 生日在 1/1 当天 → 当天 09:00', () {
      final at = nextBirthdayAt(
        DateTime(2023, 1, 1),
        DateTime(2026, 1, 1),
        0,
      );
      expect(at, DateTime(2026, 1, 1, 9));
    });
  });
}
