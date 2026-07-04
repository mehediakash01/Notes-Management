import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a single note stored in Cloud Firestore.
///
/// All Firestore serialization (`Map` ↔ `NoteModel`) is confined to this
/// class so that the rest of the application never touches raw `Map`s
/// or `DocumentSnapshot` objects.
class NoteModel {
  /// Firestore document ID. `null` for notes that have not yet been
  /// persisted (i.e. the user is creating a new note locally).
  final String? id;

  /// Short headline of the note.
  final String title;

  /// Free-form body / description of the note.
  final String description;

  /// Server-side creation timestamp. Optional because Firestore may
  /// populate it after the first write.
  final DateTime? createdAt;

  const NoteModel({
    this.id,
    required this.title,
    required this.description,
    this.createdAt,
  });

  /// Convenience copy-with used when editing a note locally before
  /// pushing the change back to Firestore.
  NoteModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes this note to a plain `Map` suitable for `set`/`update`.
  ///
  /// `createdAt` is written as a Firestore `Timestamp` so that
  /// server-side ordering (`orderBy('createdAt', descending: true)`)
  /// works correctly across clients.
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Builds a [NoteModel] from a Firestore [DocumentSnapshot], pulling
  /// the document id directly from the snapshot rather than the data map.
  factory NoteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final dynamic rawCreatedAt = data['createdAt'];
    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    }

    return NoteModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, description: $description, createdAt: $createdAt)';
  }
}
