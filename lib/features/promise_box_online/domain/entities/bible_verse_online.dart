import 'package:equatable/equatable.dart';

class BibleVerseOnline extends Equatable {
  final String book;
  final String chapter;
  final String verse;
  final String sentence;

  const BibleVerseOnline({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.sentence,
  });

  String get reference => '$book $chapter:$verse';

  @override
  List<Object?> get props => [book, chapter, verse, sentence];
}
