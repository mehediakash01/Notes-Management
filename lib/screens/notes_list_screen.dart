import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/firestore_service.dart';
import '../widgets/note_card.dart';
import 'add_edit_note_screen.dart';

/// Primary Dashboard screen for the Notes app.
///
/// Renders a live, ordered list of notes from Cloud Firestore via
/// [FirestoreService.getNotesStream]. The screen is intentionally
/// declarative — it owns no caching of its own beyond what the stream
/// provides, and it never reaches into Firestore directly.
class NotesListScreen extends StatefulWidget {
  final FirestoreService service;

  const NotesListScreen({super.key, required this.service});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  // Cached last good list so connection blips don't blank the UI.
  List<NoteModel>? _lastNotes;

  Future<void> _openEditor({NoteModel? existing}) async {
    final NoteModel? result = await Navigator.of(context).push<NoteModel>(
      MaterialPageRoute<NoteModel>(
        builder: (_) => AddEditNoteScreen(
          service: widget.service,
          note: existing,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Note added' : 'Note updated',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(NoteModel note) async {
    final bool confirmed = await showDeleteNoteConfirmation(context, note: note);
    if (!confirmed) return;

    try {
      await widget.service.deleteNote(note.id!);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete note.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: const <Widget>[_NotesCountBadge()],
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: widget.service.getNotesStream(),
        builder: (BuildContext context,
            AsyncSnapshot<List<NoteModel>> snapshot) {
          // Connection-state UX: keep the last known list visible while
          // waiting for the next event, instead of flashing a spinner.
          if (snapshot.hasData) {
            _lastNotes = snapshot.data;
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _lastNotes == null) {
            return const _CenteredLoader();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final List<NoteModel> notes = _lastNotes ?? const <NoteModel>[];

          if (notes.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final NoteModel note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => _openEditor(existing: note),
                onEdit: () => _openEditor(existing: note),
                onDelete: () => _confirmDelete(note),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'New note',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
    );
  }
}

/// Small circular counter rendered in the AppBar's `actions` slot.
/// Hidden when there are no notes yet.
class _NotesCountBadge extends StatelessWidget {
  const _NotesCountBadge();

  @override
  Widget build(BuildContext context) {
    // Pull the current list count from the parent screen via the same
    // stream — keeps the badge live without requiring prop drilling.
    final FirestoreService service = FirestoreServiceScope.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: StreamBuilder<List<NoteModel>>(
        stream: service.getNotesStream(),
        builder: (BuildContext context,
            AsyncSnapshot<List<NoteModel>> snapshot) {
          final int? count = snapshot.hasData ? snapshot.data!.length : null;
          if (count == null || count == 0) return const SizedBox.shrink();

          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFF00F5D4),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1E),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF24242A),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.sticky_note_2_outlined,
                size: 44,
                color: Color(0xFF00F5D4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your thought canvas is empty.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA0A6),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap “New note” to capture your first idea.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6F767E),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Color(0xFFFF5252),
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn’t load notes.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9AA0A6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
