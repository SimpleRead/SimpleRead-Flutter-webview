import 'package:add_2_calendar/add_2_calendar.dart';

/// Signature for the actual calendar-insert call, injected for testability
/// -- same DI shape as [ContentDownloadHandler]'s injected download call.
typedef AddToCalendarFn = Future<bool> Function(Event event);

/// Real handler for `calendar.event` -- `add_2_calendar`.
///
/// Chosen over `device_calendar` after checking pub.dev for both (see
/// pubspec.yaml): `add_2_calendar` was published 2026-06-15 with a full
/// 160/160 pub score; `device_calendar` was last published 2024-09-29 at
/// 130/160. Needs only OS calendar permission (`NSCalendarsUsageDescription`
/// on iOS, requested via the plugin itself); no external account.
class CalendarEventHandler {
  CalendarEventHandler({AddToCalendarFn? addToCalendar})
      : _addToCalendar = addToCalendar ?? Add2Calendar.addEvent2Cal;

  final AddToCalendarFn _addToCalendar;

  /// Matches the `calendar.event` response shape from the contract:
  /// `{success, reason?}`. `startsAt` is an ISO-8601 string; the event is
  /// given a 1-hour default duration since the contract carries no end time.
  Future<Map<String, dynamic>> handle(Map<String, dynamic> payload) async {
    final title = payload['title'];
    final startsAt = payload['startsAt'];
    if (title is! String || title.isEmpty || startsAt is! String) {
      return const {'success': false, 'reason': 'failed'};
    }

    final start = DateTime.tryParse(startsAt);
    if (start == null) {
      return const {'success': false, 'reason': 'failed'};
    }

    try {
      final added = await _addToCalendar(Event(
        title: title,
        startDate: start,
        endDate: start.add(const Duration(hours: 1)),
      ));
      return added
          ? const {'success': true}
          : const {'success': false, 'reason': 'user_cancelled'};
    } on Object {
      return const {'success': false, 'reason': 'failed'};
    }
  }
}
