import '../entities/bible_verse.dart';

abstract class BibleRepository {
  Future<List<BibleVerse>> getVerses();
}
