import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/bible_verse.dart';
import '../../domain/repositories/bible_repository.dart';
import '../models/bible_verse_model.dart';

class BibleRepositoryImpl implements BibleRepository {
  @override
  Future<List<BibleVerse>> getVerses() async {
    try {
      final String response = await rootBundle.loadString('assets/data/bible_verses.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => BibleVerseModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load verses: $e');
    }
  }
}
