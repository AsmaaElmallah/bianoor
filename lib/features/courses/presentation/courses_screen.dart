import 'package:flutter/material.dart';

import 'course_detail_screen.dart';

/// Home of «الدورات»: intro + course strip + lessons. No separate catalog.
class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key, this.embedded = false});

  /// When true (bottom-nav tab), hide back and nest cleanly in the home shell.
  final bool embedded;

  @override
  Widget build(BuildContext context) => CoursesHubScreen(embedded: embedded);
}
