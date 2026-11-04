import 'package:flutter_test/flutter_test.dart';
import 'package:bloco_de_nota_turma_a/models/note.dart';
import 'package:bloco_de_nota_turma_a/utils/note_sort.dart';

Note example(String title, String updatedAt) => Note(
  uid: 'usuario',
  title: title,
  content: 'Conteúdo',
  date: '03/11/2026',
  updatedAt: updatedAt,
);

void main() {
  test('ordena notas da mais recente para a mais antiga', () {
    final notes = [
      example('Antiga', '2026-11-01T10:00:00.000Z'),
      example('Recente', '2026-11-03T10:00:00.000Z'),
      example('Intermediária', '2026-11-02T10:00:00.000Z'),
    ];
    final ordered = sortNotesByUpdate(notes);
    expect(ordered.map((note) => note.title).toList(), [
      'Recente', 'Intermediária', 'Antiga',
    ]);
    expect(notes.first.title, 'Antiga');
  });

  test('datas inválidas ficam depois das válidas', () {
    final ordered = sortNotesByUpdate([
      example('Sem data', ''),
      example('Válida', '2026-11-03T10:00:00.000Z'),
    ]);
    expect(ordered.first.title, 'Válida');
  });

  test('nota mantém categoria e título independentes', () {
    final note = example('Lista de compras', '2026-11-03T10:00:00.000Z');
    expect(note.title, 'Lista de compras');
    expect(note.category, 'Pessoal');
  });
}
