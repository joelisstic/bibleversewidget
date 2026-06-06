import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'features/promise_box_online/data/models/bible_model.dart';

class VerseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getVerses() async {
    final snapshot = await _db.collection('BIBLE_VERSE').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

Future<void> uploadVersesToFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final String response = await rootBundle.loadString('assets/data/bible_verses.json');
  final List<dynamic> data = json.decode(response);

  for (var verse in data) {
    await firestore.collection('BIBLE_VERSE').add({
      "BOOK": verse["book"],
      "CHAPTER": verse["chapter"],
      "VERSE": verse["verse"],
      "SENTENCE": verse["sentence"],
    });
  }
  print("Upload completed ✅");
}

Future<void> uploadBibleToFirestore() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print("🚀 Starting optimized Bible upload...");
    final String response = await rootBundle.loadString('assets/data/ENGLISH_STANDARD_VERSION.json');
    final Map<String, dynamic> jsonData = json.decode(response);
    final bible = BibleModel.fromJson(jsonData);
    final bookNames = bible.books.keys.toList();

    final booksSnap = await firestore.collection('ALL_BIBLE_VERSES').get();
    final existingBooks = {for (var doc in booksSnap.docs) doc.id: doc.data()};

    int startBookIdx = 0;
    int startChapterIdx = 0;
    int startVerseIdx = 0;

    int lastFoundBookIdx = -1;
    for (int i = 0; i < bookNames.length; i++) {
      if (existingBooks.containsKey(bookNames[i])) {
        lastFoundBookIdx = i;
      } else {
        break; 
      }
    }

    if (lastFoundBookIdx != -1) {
      String bookName = bookNames[lastFoundBookIdx];
      bool isBookCompleted = existingBooks[bookName]?['is_completed'] ?? false;
      if (isBookCompleted) {
        startBookIdx = lastFoundBookIdx + 1;
      } else {
        startBookIdx = lastFoundBookIdx;
        final chaptersSnap = await firestore.collection('ALL_BIBLE_VERSES').doc(bookName).collection('chapters').get();
        final existingChapters = {for (var doc in chaptersSnap.docs) doc.id: doc.data()};
        final chapterKeys = bible.books[bookName]!.chapters.keys.toList();
        
        int lastFoundChapterIdx = -1;
        for (int j = 0; j < chapterKeys.length; j++) {
          if (existingChapters.containsKey(chapterKeys[j])) lastFoundChapterIdx = j;
          else break;
        }

        if (lastFoundChapterIdx != -1) {
          String chapterId = chapterKeys[lastFoundChapterIdx];
          if (existingChapters[chapterId]?['is_completed'] ?? false) {
            startChapterIdx = lastFoundChapterIdx + 1;
          } else {
            startChapterIdx = lastFoundChapterIdx;
            final versesSnap = await firestore.collection('ALL_BIBLE_VERSES').doc(bookName).collection('chapters').doc(chapterId).collection('verses').get();
            final existingVerseIds = versesSnap.docs.map((d) => d.id).toSet();
            final verseKeys = bible.books[bookName]!.chapters[chapterId]!.verses.keys.toList();
            int lastFoundVerseIdx = -1;
            for (int k = 0; k < verseKeys.length; k++) {
              if (existingVerseIds.contains(verseKeys[k])) lastFoundVerseIdx = k;
              else break;
            }
            startVerseIdx = lastFoundVerseIdx + 1;
          }
        }
      }
    }

    if (startBookIdx >= bookNames.length) {
      print("✅ Bible already fully uploaded.");
      return;
    }

    for (int i = startBookIdx; i < bookNames.length; i++) {
      final bookName = bookNames[i];
      final book = bible.books[bookName]!;
      final bookRef = firestore.collection('ALL_BIBLE_VERSES').doc(bookName);
      await bookRef.set({"name": bookName, "is_completed": false}, SetOptions(merge: true));

      final chapterKeys = book.chapters.keys.toList();
      for (int j = (i == startBookIdx ? startChapterIdx : 0); j < chapterKeys.length; j++) {
        final chapterNumber = chapterKeys[j];
        final chapter = book.chapters[chapterNumber]!;
        final chapterRef = bookRef.collection('chapters').doc(chapterNumber);
        await chapterRef.set({"chapter": chapterNumber, "is_completed": false}, SetOptions(merge: true));

        final verseKeys = chapter.verses.keys.toList();
        for (int k = (i == startBookIdx && j == startChapterIdx ? startVerseIdx : 0); k < verseKeys.length; k++) {
          final verseNumber = verseKeys[k];
          await chapterRef.collection('verses').doc(verseNumber).set({
            "verse": verseNumber,
            "sentence": chapter.verses[verseNumber],
          });
          if (k % 25 == 0) await Future.delayed(const Duration(milliseconds: 50));
        }
        await chapterRef.set({"is_completed": true}, SetOptions(merge: true));
      }
      await bookRef.set({"is_completed": true}, SetOptions(merge: true));
    }
    print("🔥 Bible Upload Complete.");
  } catch (e) {
    print("❌ Upload Error: $e");
  }
}
