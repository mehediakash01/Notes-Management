import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/firestore_service.dart';

/// Editor screen used by [NotesListScreen] for both creating and
/// editing notes. The full editor UX (validation, save flow, error
/// states) is implemented in a later step; this stub exists so the
/// dashboard compiles and the routing wiring is in place.
class NoteEditorScreen extends StatefulWidget {
  final FirestoreService service;
  final NoteModel? existing;

  const NoteEditorScreen({
    super.key,
    required this.service,
    this.existing,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    final NoteModel draft = NoteModel(
      id: widget.existing?.id,
      title: title,
      description: description,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existing == null) {
        await widget.service.addNote(draft);
      } else {
        await widget.service.updateNote(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop<NoteModel>(draft);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save note.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit note' : 'New note'),
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00F5D4),
            ),
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Description',
                  alignLabelWithHint: true,
                ),
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
