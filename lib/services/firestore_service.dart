import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note_model.dart';

/// Single point of contact between the app and Cloud Firestore.
///
/// The UI layer (widgets, blocs, providers, etc.) must depend on this
/// service rather than touching `FirebaseFirestore` directly. This keeps
/// Firestore concerns — collection paths, ordering, error handling —
/// in one testable, swappable place.
class FirestoreService {
  /// Backing Firestore instance. Exposed through a getter so tests can
  /// inject a fake without changing call sites.
  final FirebaseFirestore _db;

  /// Name of the collection that stores notes.
  static const String notesCollection = 'notes';

  /// Creates a service backed by the default `FirebaseFirestore.instance`.
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Reference to the `notes` collection.
  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection(notesCollection);

  /// Adds a new note to Firestore.
  ///
  /// If [NoteModel.id] is `null`, Firestore generates one and the
  /// resulting `DocumentReference.id` is ignored — callers that need
  /// the generated id should follow up via the returned reference.
  Future<void> addNote(NoteModel note) async {
    final DocumentReference<Map<String, dynamic>> docRef = note.id != null
        ? _notesRef.doc(note.id)
        : _notesRef.doc();

    await docRef.set(note.toFirestore());
  }

  /// Live stream of all notes ordered by `createdAt` descending.
  ///
  /// Emits a fresh `List<NoteModel>` every time the underlying
  /// collection changes. Mapping from `QuerySnapshot` to model list
  /// happens here so the UI never sees raw Firestore objects.
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

  /// Replaces the document identified by [NoteModel.id] with the
  /// supplied note's data.
  ///
  /// Throws if [NoteModel.id] is `null` — you cannot update a note that
  /// has not been persisted yet.
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

  /// Deletes the note with the given Firestore document [id].
  Future<void> deleteNote(String id) async {
    await _notesRef.doc(id).delete();
  }
}