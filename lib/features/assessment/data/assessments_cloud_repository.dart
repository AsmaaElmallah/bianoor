import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';

class CloudAssessment {
  const CloudAssessment({
    required this.id,
    required this.title,
    required this.kind,
    required this.questions,
  });

  final String id;
  final String title;
  final String kind;
  final List<CloudAssessmentQuestion> questions;
}

class CloudAssessmentQuestion {
  const CloudAssessmentQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.correctIndex,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int? correctIndex;
}

final assessmentsCloudRepositoryProvider =
    Provider<AssessmentsCloudRepository>((ref) {
  return AssessmentsCloudRepository();
});

final cloudAssessmentProvider =
    FutureProvider.family<CloudAssessment?, String>((ref, assessmentId) {
  return ref
      .watch(assessmentsCloudRepositoryProvider)
      .fetchPublished(assessmentId);
});

class AssessmentsCloudRepository {
  Future<bool> _ready() async {
    if (!SupabaseBootstrap.isEnabled) return false;
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    return SupabaseBootstrap.isReady;
  }

  Future<CloudAssessment?> fetchPublished(String assessmentId) async {
    if (!await _ready()) return null;
    try {
      final row = await SupabaseBootstrap.client
          .from('assessments')
          .select()
          .eq('id', assessmentId)
          .eq('publish_status', 'published')
          .maybeSingle();
      if (row == null) return null;

      final qRows = await SupabaseBootstrap.client
          .from('assessment_questions')
          .select()
          .eq('assessment_id', assessmentId)
          .order('sort_order');

      final questions = <CloudAssessmentQuestion>[];
      for (final q in List<Map<String, dynamic>>.from(qRows as List)) {
        final rawOptions = q['options'];
        List<String> options = const [];
        if (rawOptions is List) {
          options = rawOptions.map((e) => e.toString()).toList();
        }
        questions.add(
          CloudAssessmentQuestion(
            id: q['id'] as String,
            prompt: q['prompt'] as String? ?? '',
            options: options,
            correctIndex: q['correct_index'] as int?,
          ),
        );
      }

      return CloudAssessment(
        id: row['id'] as String,
        title: row['title'] as String? ?? assessmentId,
        kind: row['kind'] as String? ?? 'quiz',
        questions: questions,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Assessments] $assessmentId failed: $e\n$st');
      return null;
    }
  }
}
