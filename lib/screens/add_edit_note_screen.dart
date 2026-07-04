import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note_model.dart';
import '../services/firestore_service.dart';

class AddEditNoteScreen extends StatefulWidget {
  final FirestoreService service;
  final NoteModel? note;

  const AddEditNoteScreen({
    super.key,
    required this.service,
    this.note,
  });

  bool get isEditing => note != null;

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  static const Color _neonTeal = Color(0xFF00F5D4);
  static const Color _mutedGrey = Color(0xFF9AA0A6);
  static const Color _errorRed = Color(0xFFFF5252);
  static const Color _surface = Color(0xFF1A1A1E);
  static const Color _divider = Color(0xFF24242A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  bool _isLoading = false;
  bool _titleFocused = false;
  bool _descriptionFocused = false;

  @override
  void initState() {
    super.initState();

    final NoteModel? note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _descriptionController.text = note.description;
    }

    _titleFocus.addListener(_handleFocusChange);
    _descriptionFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _titleFocused = _titleFocus.hasFocus;
      _descriptionFocused = _descriptionFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.removeListener(_handleFocusChange);
    _titleFocus.dispose();
    _descriptionFocus.removeListener(_handleFocusChange);
    _descriptionFocus.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  Future<void> _onSavePressed() async {
    if (_isLoading) return;

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      if (_titleController.text.trim().isEmpty) {
        _titleFocus.requestFocus();
      } else {
        _descriptionFocus.requestFocus();
      }
      return;
    }

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final NoteModel? original = widget.note;

    setState(() => _isLoading = true);

    final NoteModel draft = NoteModel(
      id: original?.id,
      title: title,
      description: description,
      createdAt: original?.createdAt ?? DateTime.now(),
    );

    try {
      if (original == null) {
        await widget.service.addNote(draft);
      } else {
        await widget.service.updateNote(draft);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(original == null ? 'Note added' : 'Note updated'),
        ),
      );

      Navigator.of(context).pop<NoteModel>(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _surface,
          content: const Text(
            'Could not save note. Please try again.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.isEditing;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Note' : 'New Note'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: _isLoading ? null : _onSavePressed,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_neonTeal),
                        ),
                      )
                    : const Icon(Icons.check, color: _neonTeal, size: 20),
                label: Text(
                  _isLoading ? 'Saving…' : 'Save',
                  style: const TextStyle(
                    color: _neonTeal,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                style: TextButton.styleFrom(
                  disabledForegroundColor: _neonTeal.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _isLoading,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTitleField(),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 1,
                    color: _titleFocused ? _neonTeal : _divider,
                  ),
                  const SizedBox(height: 20),
                  _buildDescriptionLabel(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildDescriptionField()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      enabled: !_isLoading,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.1,
      ),
      cursorColor: _neonTeal,
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: const TextStyle(
          color: _mutedGrey,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        errorStyle: const TextStyle(
          color: _errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(120),
      ],
      validator: _validateRequired,
    );
  }

  Widget _buildDescriptionLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Description',
        style: TextStyle(
          color: _descriptionFocused ? _neonTeal : _mutedGrey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocus,
      enabled: !_isLoading,
      expands: true,
      maxLines: null,
      minLines: null,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      cursorColor: _neonTeal,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText:
            'Start writing your thoughts, ideas, or anything worth remembering…',
        hintStyle: const TextStyle(
          color: _mutedGrey,
          fontSize: 15,
          height: 1.45,
        ),
        filled: true,
        fillColor: _surface,
        isDense: true,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _neonTeal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _errorRed, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _divider, width: 1),
        ),
        errorStyle: const TextStyle(
          color: _errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(4000),
      ],
      validator: _validateRequired,
    );
  }
}

Future<bool> showDeleteNoteConfirmation(
  BuildContext context, {
  required NoteModel note,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF24242A), width: 1),
        ),
        title: const Text(
          'Delete note?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          note.title.trim().isEmpty
              ? 'This note will be permanently removed. This action cannot be undone.'
              : '"${note.title}" will be permanently removed. '
                  'This action cannot be undone.',
          style: const TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9AA0A6),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5252),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}