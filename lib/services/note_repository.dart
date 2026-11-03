import 'package:bloco_de_nota_turma_a/database/database_helper.dart';
import 'package:bloco_de_nota_turma_a/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NoteRepository {
  static final NoteRepository instance = NoteRepository._();
  NoteRepository._();

  final DatabaseHelper local = DatabaseHelper.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String uid) =>
      firestore.collection('users').doc(uid).collection('notes');

  Map<String, dynamic> cloudMap(Note note) => {
    'uid': note.uid,
    'title': note.title,
    'content': note.content,
    'date': note.date,
    'category': note.category,
    'syncId': note.syncId,
    'updatedAt': note.updatedAt,
    'isDeleted': note.isDeleted,
  };

  Note fromCloud(String uid, String id, Map<String, dynamic> map) => Note(
    uid: uid,
    title: map['title'] as String? ?? '',
    content: map['content'] as String? ?? '',
    date: map['date'] as String? ?? '',
    category: map['category'] as String? ?? 'Pessoal',
    syncId: id,
    updatedAt: map['updatedAt'] as String? ?? '',
    syncStatus: 1,
    isDeleted: map['isDeleted'] == true,
  );

  Future<void> save(Note note) async {
    if (kIsWeb) {
      await collection(note.uid).doc(note.syncId).set(cloudMap(note));
      return;
    }
    if (note.id == null) {
      await local.insertNote(note);
    } else {
      await local.updateNote(note);
    }
    try {
      await synchronize(note.uid);
    } catch (_) {}
  }

  Future<void> delete(Note note) async {
    final deleted = Note(
      id: note.id,
      uid: note.uid,
      title: note.title,
      content: note.content,
      date: note.date,
      category: note.category,
      syncId: note.syncId,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      isDeleted: true,
      syncStatus: 0,
    );
    if (kIsWeb) {
      await collection(note.uid).doc(note.syncId).set(cloudMap(deleted));
      return;
    }
    await local.updateNote(deleted);
    try {
      await synchronize(note.uid);
    } catch (_) {}
  }

  Future<List<Note>> getNotes(String uid, {String search = '', String? category}) async {
    if (kIsWeb) {
      final snapshot = await collection(uid).get();
      final query = search.trim().toLowerCase();
      final notes = snapshot.docs
          .map((doc) => fromCloud(uid, doc.id, doc.data()))
          .where((note) => !note.isDeleted)
          .where((note) => category == null || category == 'Todas' || note.category == category)
          .where((note) => query.isEmpty || note.title.toLowerCase().contains(query) || note.content.toLowerCase().contains(query))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    }
    return local.getNotes(uid, search: search, category: category);
  }

  Future<List<String>> getCategories(String uid) async {
    if (!kIsWeb) return local.getCategories(uid);
    final notes = await getNotes(uid);
    final values = {'Pessoal', 'Estudos', 'Trabalho', 'Outros', ...notes.map((n) => n.category)};
    return values.toList()..sort();
  }

  Future<void> synchronize(String uid) async {
    if (kIsWeb) return;
    final pending = await local.getPendingNotes(uid);
    for (final note in pending) {
      await collection(uid).doc(note.syncId).set(cloudMap(note));
      await local.markSynced(note.id!, uid);
    }
    final snapshot = await collection(uid).get();
    for (final doc in snapshot.docs) {
      final remote = fromCloud(uid, doc.id, doc.data());
      await local.upsertFromCloud(remote);
    }
  }
}
