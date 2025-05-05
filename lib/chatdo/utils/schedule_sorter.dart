import '../models/schedule_entry.dart';

List<ScheduleEntry> sortScheduleEntries(List<ScheduleEntry> entries, String option) {
  final list = [...entries];
  if (option == 'tag') {
    list.sort((a, b) {
      final tagA = a.tags.isNotEmpty ? a.tags.first : '';
      final tagB = b.tags.isNotEmpty ? b.tags.first : '';
      final cmp = tagA.compareTo(tagB);
      return cmp != 0 ? cmp : a.timestamp.compareTo(b.timestamp);
    });
  } else if (option == 'latest') {
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  } else {
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
  return list;
}
