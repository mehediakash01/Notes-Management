import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  static const String notesCollection = 'notes';

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection(notesCollection);

  Future<void> addNote(NoteModel note) async {
    final DocumentReference<Map<String, dynamic>> docRef = note.id != null
        ? _notesRef.doc(note.id)
        : _notesRef.doc();

    await docRef.set(note.toFirestore());
  }

  Stream<List<NoteModel>> getNotesStream() {
    return _notesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map(NoteModel.fromFirestore)
          .toList(growable: false);
    });
  }

  Future<void> updateNote(NoteModel note) async {
    if (note.id == null) {
      throw ArgumentError.value(
        note,
        'note',
        'Cannot update a NoteModel without an id. Use addNote() instead.',
      );
    }

    await _notesRef.doc(note.id).set(note.toFirestore());
  }

  Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}