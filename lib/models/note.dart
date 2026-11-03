class Note {
  final int? id;
  final String uid;
  final String title;
  final String content;
  final String date;
  final String category;
  final String syncId;
  final String updatedAt;
  final int syncStatus;
  final bool isDeleted;

  Note({
    this.id,
    required this.uid,
    required this.title,
    required this.content,
    required this.date,
    this.category = 'Pessoal',
    String? syncId,
    String? updatedAt,
    this.syncStatus = 0,
    this.isDeleted = false,
  }) : syncId = syncId ?? DateTime.now().microsecondsSinceEpoch.toString(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'content': content,
      'date': date,
      'category': category,
      'sync_id': syncId,
      'updated_at': updatedAt,
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      uid: map['uid'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      category: map['category'] as String? ?? 'Pessoal',
      syncId: map['sync_id'] as String? ?? 'legacy_${map['id']}',
      updatedAt: (map['updated_at'] as String?)?.isNotEmpty == true
          ? map['updated_at'] as String
          : map['date'] as String,
      syncStatus: map['sync_status'] as int? ?? 0,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}
