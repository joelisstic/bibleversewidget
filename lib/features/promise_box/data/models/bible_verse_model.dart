import '../../domain/entities/bible_verse.dart';

class BibleVerseModel extends BibleVerse {
  const BibleVerseModel({
    required super.book,
    required super.chapter,
    required super.verse,
    required super.sentence,
  });

  factory BibleVerseModel.fromJson(Map<String, dynamic> json) {
    return BibleVerseModel(
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? '',
      verse: json['verse'] ?? '',
      sentence: json['sentence'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'sentence': sentence,
    };
  }
}
