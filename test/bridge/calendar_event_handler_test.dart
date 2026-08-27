import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/bridge/calendar_event_handler.dart';

void main() {
  group('CalendarEventHandler.handle', () {
    test('returns failed when title is missing', () async {
      final handler = CalendarEventHandler(
        addToCalendar: (event) async => true,
      );

      final result = await handler.handle({
        'startsAt': '2026-09-01T10:00:00.000Z',
      });

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('returns failed when startsAt is not a parseable date', () async {
      final handler = CalendarEventHandler(
        addToCalendar: (event) async => true,
      );

      final result = await handler.handle({
        'title': 'Live class',
        'startsAt': 'not-a-date',
      });

      expect(result, {'success': false, 'reason': 'failed'});
    });

    test('adds a 1-hour event with the given title/start and returns success',
        () async {
      Event? captured;
      final handler = CalendarEventHandler(
        addToCalendar: (event) async {
          captured = event;
          return true;
        },
      );

      final result = await handler.handle({
        'title': 'Live class',
        'startsAt': '2026-09-01T10:00:00.000Z',
      });

      expect(result, {'success': true});
      expect(captured?.title, 'Live class');
      expect(captured?.startDate, DateTime.parse('2026-09-01T10:00:00.000Z'));
      expect(captured?.endDate, DateTime.parse('2026-09-01T11:00:00.000Z'));
    });

    test('returns user_cancelled when the plugin reports it was not added',
        () async {
      final handler = CalendarEventHandler(
        addToCalendar: (event) async => false,
      );

      final result = await handler.handle({
        'title': 'Live class',
        'startsAt': '2026-09-01T10:00:00.000Z',
      });

      expect(result, {'success': false, 'reason': 'user_cancelled'});
    });

    test('returns failed when the platform call throws', () async {
      final handler = CalendarEventHandler(
        addToCalendar: (event) async => throw Exception('permission error'),
      );

      final result = await handler.handle({
        'title': 'Live class',
        'startsAt': '2026-09-01T10:00:00.000Z',
      });

      expect(result, {'success': false, 'reason': 'failed'});
    });
  });
}
