import '../entities/bible_verse_online.dart';

abstract class BibleOnlineRepository {
  Future<List<BibleVerseOnline>> getRemoteVerses();
}
