import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String? id;
  final String title;
  final String description;
  final DateTime? createdAt;

  const NoteModel({
    this.id,
    required this.title,
    required this.description,
    this.createdAt,
  });

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

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

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
