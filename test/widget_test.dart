import 'package:flutter_test/flutter_test.dart';
import 'package:bloco_de_nota_turma_a/models/note.dart';

void main() {
  test('converte nota para mapa e recupera os dados', () {
    final note = Note(
      id: 7,
      uid: 'usuario',
      title: 'Estudar',
      content: 'Revisar Flutter',
      date: '03/11/2026 20:00',
      category: 'Estudos',
      syncId: 'nota-7',
      updatedAt: '2026-11-03T23:00:00.000Z',
    );
    final recovered = Note.fromMap(note.toMap());
    expect(recovered.title, 'Estudar');
    expect(recovered.category, 'Estudos');
    expect(recovered.syncId, 'nota-7');
    expect(recovered.content, 'Revisar Flutter');
  });
}
