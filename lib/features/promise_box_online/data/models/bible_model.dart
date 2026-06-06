class BibleModel {
  final Map<String, BookModel> books;

  BibleModel({required this.books});

  factory BibleModel.fromJson(Map<String, dynamic> json) {
    return BibleModel(
      books: json.map(
            (key, value) => MapEntry(key, BookModel.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return books.map(
          (key, value) => MapEntry(key, value.toJson()),
    );
  }
}

class BookModel {
  final Map<String, ChapterModel> chapters;

  BookModel({required this.chapters});

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      chapters: json.map(
            (key, value) => MapEntry(key, ChapterModel.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return chapters.map(
          (key, value) => MapEntry(key, value.toJson()),
    );
  }
}

class ChapterModel {
  final Map<String, String> verses;

  ChapterModel({required this.verses});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      verses: json.map(
            (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return verses;
  }
}