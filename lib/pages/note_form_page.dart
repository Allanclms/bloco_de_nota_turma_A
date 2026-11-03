import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

class NoteFormPage extends StatefulWidget {
  final Note? note;

  const NoteFormPage({super.key, this.note});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final database = DatabaseHelper.instance;
  String selectedCategory = 'Pessoal';
  List<String> categories = ['Pessoal', 'Estudos', 'Trabalho', 'Outros'];
  bool saving = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
      selectedCategory = widget.note!.category;
    }
    loadCategories();
  }

  Future<void> loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final result = await database.getCategories(user.uid);
    if (!mounted) return;
    setState(() {
      categories = result;
      if (!categories.contains(selectedCategory)) {
        categories.add(selectedCategory);
      }
    });
  }

  Future<void> addCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (category == null || category.isEmpty) return;
    if (!mounted) return;
    setState(() {
      if (!categories.contains(category)) categories.add(category);
      selectedCategory = category;
    });
  }

  Future<void> saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || saving) return;
    final content = contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o conteúdo da nota.')),
      );
      return;
    }

    setState(() => saving = true);
    final now = DateTime.now();
    final date = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} ${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    final note = Note(
      id: widget.note?.id,
      uid: user.uid,
      title: titleController.text.trim(),
      content: content,
      date: date,
      category: selectedCategory,
      syncId: widget.note?.syncId,
      updatedAt: now.toIso8601String(),
      syncStatus: 0,
      isDeleted: false,
    );

    try {
      if (isEditing) {
        await database.updateNote(note);
      } else {
        await database.insertNote(note);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a nota.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar nota' : 'Nova nota',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: saving ? null : saveNote,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292333),
              ),
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedCategory = value);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Criar categoria'),
              ),
            ),
            const Divider(color: Color(0xFFE4DFEA)),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Color(0xFF40394A),
                ),
                decoration: const InputDecoration(
                  hintText: 'Comece a escrever...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
