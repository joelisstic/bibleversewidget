import '../entities/bible_verse.dart';
import '../repositories/bible_repository.dart';

class GetVerses {
  final BibleRepository repository;

  GetVerses(this.repository);

  Future<List<BibleVerse>> call() async {
    return await repository.getVerses();
  }
}
