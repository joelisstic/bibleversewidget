import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class VerseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getVerses() async {
    final snapshot = await _db.collection('BIBLE_VERSE').get();
    debugPrint("verses: ${snapshot.docs.map((doc) => doc.data()).toList()}");

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}





Future<void> uploadVersesToFirestore() async {
  final firestore = FirebaseFirestore.instance;

  final String response =
  await rootBundle.loadString('assets/data/bible_verses.json');

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