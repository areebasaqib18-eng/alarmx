import 'package:alarmx/alarm_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 21 Oct 2026, 10:00.
  final wed10am = DateTime(2026, 10, 21, 10, 0);

  test('one-time alarm later today rings today', () {
    final t = AlarmScheduler.nextOccurrence(11, 0, 'Never', from: wed10am);
    expect(t, DateTime(2026, 10, 21, 11, 0));
  });

  test('one-time alarm already past rings tomorrow', () {
    final t = AlarmScheduler.nextOccurrence(9, 0, 'Never', from: wed10am);
    expect(t, DateTime(2026, 10, 22, 9, 0));
  });

  test('alarm at the exact current minute rings tomorrow, not now', () {
    final t = AlarmScheduler.nextOccurrence(10, 0, 'Every Day', from: wed10am);
    expect(t, DateTime(2026, 10, 22, 10, 0));
  });

  test('weekdays skips the weekend', () {
    final fri = DateTime(2026, 10, 23, 10, 0);
    final t = AlarmScheduler.nextOccurrence(9, 0, 'Weekdays', from: fri);
    expect(t, DateTime(2026, 10, 26, 9, 0)); // Monday
  });

  test('weekends skips weekdays', () {
    final t = AlarmScheduler.nextOccurrence(9, 0, 'Weekends', from: wed10am);
    expect(t, DateTime(2026, 10, 24, 9, 0)); // Saturday
  });

  test('month and year rollover', () {
    final t = AlarmScheduler.nextOccurrence(
      7,
      0,
      'Every Day',
      from: DateTime(2026, 12, 31, 23, 0),
    );
    expect(t, DateTime(2027, 1, 1, 7, 0));
  });

  test('isRepeating', () {
    expect(AlarmScheduler.isRepeating('Never'), isFalse);
    expect(AlarmScheduler.isRepeating('Every Day'), isTrue);
    expect(AlarmScheduler.isRepeating('Weekdays'), isTrue);
    expect(AlarmScheduler.isRepeating('Weekends'), isTrue);
  });
}
