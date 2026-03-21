import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../../domain/entities/bible_verse_online.dart';
import '../../domain/repositories/bible_online_repository.dart';
import '../models/bible_verse_online_model.dart';

class BibleOnlineRepositoryImpl implements BibleOnlineRepository {
  // Use a getter to avoid accessing Firebase before initialization
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<List<BibleVerseOnline>> getRemoteVerses() async {
      final snapshot = await _firestore.collection('BIBLE_VERSE').get();
      debugPrint("verses: ${snapshot.docs.map((doc) => doc.data()).toList()}");

      return snapshot.docs
          .map((doc) => BibleVerseOnlineModel.fromJson(doc.data()))
          .toList();
    // } catch (e) {
    //   throw Exception('Failed to load remote verses: $e');
    // }
  }
}
