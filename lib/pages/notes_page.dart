import 'package:bloco_de_nota_turma_a/services/note_repository.dart';
import 'package:bloco_de_nota_turma_a/models/note.dart';
import 'package:bloco_de_nota_turma_a/pages/login_page.dart';
import 'package:bloco_de_nota_turma_a/pages/note_form_page.dart';
import 'package:bloco_de_nota_turma_a/services/auth_service.dart';
import 'package:bloco_de_nota_turma_a/widgets/note_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteRepository repository = NoteRepository.instance;
  final AuthService authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  List<Note> notes = [];
  List<String> categories = ['Todas'];
  String selectedCategory = 'Todas';
  bool loading = true;
  bool syncing = false;
  String? syncError;

  @override
  void initState() {
    super.initState();
    syncNotes();
  }

  Future<void> loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final result = await repository.getNotes(
        user.uid,
        search: searchController.text,
        category: selectedCategory,
      );
      final savedCategories = await repository.getCategories(user.uid);
      if (!mounted) return;
      setState(() {
        notes = result;
        categories = ['Todas', ...savedCategories];
        loading = false;
        syncError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        syncError = 'Não foi possível carregar as notas. Verifique a conexão e as regras do Firestore.';
      });
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await repository.delete(note);
      await loadNotes();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a nota.')),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota deletada com sucesso!')),
      );
    }
  }

  Future<void> syncNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || syncing) return;
    setState(() => syncing = true);
    try {
      await repository.synchronize(user.uid);
      await loadNotes();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronização concluída.')),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem conexão ou acesso ao Firestore. As alterações locais continuam salvas no Android.')),
      );
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> openEditNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(note: note)),
    );
    await loadNotes();
  }

  Future<void> openNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormPage()),
    );
    await loadNotes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas notas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: syncing ? null : syncNotes,
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openNewNote,
        backgroundColor: const Color(0xff6c4ab6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova Nota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Color(0xFF77717f),
                fontSize: 13,
              ),
            ),
            if (syncError != null) ...[
              Text(syncError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: (_) => loadNotes(),
              decoration: InputDecoration(
                hintText: 'Pesquisar título ou conteúdo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    loadNotes();
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filtrar categoria',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedCategory = value);
                loadNotes();
              },
            ),
            const SizedBox(height: 16),
            if (loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (notes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xffede5fa),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sticky_note_2_rounded,
                          color: Color(0xff6c4ab6),
                          size: 45,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        searchController.text.isNotEmpty ||
                                selectedCategory != 'Todas'
                            ? 'Nenhuma nota encontrada'
                            : 'Nenhuma nota ainda',
                      ),
                      const SizedBox(height: 8),
                      const Text('Crie sua primeira nota.'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => openEditNote(note),
                      onDelete: () => deleteNote(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
