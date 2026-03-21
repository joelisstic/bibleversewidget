import '../../domain/entities/bible_verse_online.dart';

class BibleVerseOnlineModel extends BibleVerseOnline {
  const BibleVerseOnlineModel({
    required super.book,
    required super.chapter,
    required super.verse,
    required super.sentence,
  });

  factory BibleVerseOnlineModel.fromJson(Map<String, dynamic> json) {
    return BibleVerseOnlineModel(
      book: json['BOOK'] ?? '',
      chapter: json['CHAPTER'] ?? '',
      // Correcting mapping based on Firestore screenshot:
      // VERSE in Firestore is the long text ("Delight yourself...")
      // SENTENCE in Firestore is the verse number ("4")
      verse: json['VERSE'] ?? '',
      sentence: json['SENTENCE'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BOOK': book,
      'CHAPTER': chapter,
      'SENTENCE': sentence,
      'VERSE': verse,
    };
  }
}
