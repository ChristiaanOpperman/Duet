import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question.dart';

/// Loads the bundled question pack from `assets/questions/questions.json`.
///
/// The pack is a plain JSON file so questions can be edited by hand without
/// touching Dart. Parsing is strict — a malformed entry throws rather than
/// being silently skipped, so a typo shows up immediately.
class QuestionRepository {
  QuestionRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/questions/questions.json';

  final AssetBundle _bundle;
  List<Question>? _cache;

  Future<List<Question>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final entries = decoded['questions'] as List<dynamic>;

    final questions = [
      for (final entry in entries)
        Question.fromJson(entry as Map<String, dynamic>),
    ];

    final ids = questions.map((q) => q.id).toSet();
    if (ids.length != questions.length) {
      throw const FormatException('Duplicate question ids in the pack');
    }

    return _cache = List.unmodifiable(questions);
  }
}
