import 'package:cloud_firestore/cloud_firestore.dart';

class SharedVerseModel {
  final String book;
  final String chapter;
  final String verse;
  final String sentence;
  final String senderName;
  final DateTime createdAt;

  SharedVerseModel({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.sentence,
    required this.senderName,
    required this.createdAt,
  });

  factory SharedVerseModel.fromJson(Map<String, dynamic> json) {
    return SharedVerseModel(
      book: json['BOOK'] ?? '',
      chapter: json['CHAPTER'] ?? '',
      verse: json['SENTENCE'] ?? '',
      sentence: json['VERSE'] ?? '',
      senderName: json['SENDER_NAME'] ?? 'Partner',
      createdAt: (json['CREATED_AT'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BOOK': book,
      'CHAPTER': chapter,
      'SENTENCE': verse,
      'VERSE': sentence,
      'SENDER_NAME': senderName,
      'CREATED_AT': FieldValue.serverTimestamp(),
    };
  }
}
