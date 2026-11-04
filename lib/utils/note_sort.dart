import '../models/note.dart';

List<Note> sortNotesByUpdate(Iterable<Note> notes) {
  final result = notes.toList();
  result.sort((a, b) {
    final dateA = DateTime.tryParse(a.updatedAt);
    final dateB = DateTime.tryParse(b.updatedAt);
    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1;
    if (dateB == null) return -1;
    return dateB.compareTo(dateA);
  });
  return result;
}
