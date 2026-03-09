import 'package:equatable/equatable.dart';

class BibleVerse extends Equatable {
  final String book;
  final String chapter;
  final String verse;
  final String sentence;

  const BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.sentence,
  });

  String get reference => '$book $chapter:$verse';

  @override
  List<Object?> get props => [book, chapter, verse, sentence];
}
