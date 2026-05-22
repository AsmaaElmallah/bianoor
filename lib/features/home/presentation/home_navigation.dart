import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/home_menu_item.dart';
import 'curriculum_about_screen.dart';
import 'how_to_teach_screen.dart';
import 'parent_culture_screen.dart';
import 'parent_health_culture_screen.dart';
import '../../assessment/presentation/aptitude_test_screen.dart';
import '../../activities/presentation/activities_age_groups_screen.dart';
import '../../exercises/presentation/exercises_age_groups_screen.dart';

void openHomeMenuItem(BuildContext context, HomeMenuItem item) {
  if (item.id == 'lesson_quran') {
    context.push(AppRoutes.quranJourney);
    return;
  }
  if (item.id == 'lesson_math') {
    context.push(AppRoutes.mathJourney);
    return;
  }
  if (item.id == 'lesson_visual') {
    context.push(AppRoutes.visualJourney);
    return;
  }
  if (item.id == 'lesson_emotional') {
    context.push(AppRoutes.emotionalJourney);
    return;
  }
  if (item.id == 'curriculum_about') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CurriculumAboutScreen()),
    );
    return;
  }
  if (item.id == 'how_to_teach') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HowToTeachScreen()),
    );
    return;
  }
  if (item.id == 'parent_general_culture') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ParentGeneralCultureScreen()),
    );
    return;
  }
  if (item.id == 'parent_health_culture') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ParentHealthCultureScreen()),
    );
    return;
  }
  if (item.id == 'aptitude_test') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AptitudeTestScreen()),
    );
    return;
  }
  if (item.id == 'baby_exercises') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExercisesAgeGroupsScreen()),
    );
    return;
  }
  if (item.id == 'activities' || item.id == 'apply_activities') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ActivitiesAgeGroupsScreen()),
    );
    return;
  }
  if (item.id == 'nature_sounds' || item.id == 'calm_music' || item.id == 'lullabies') {
    context.push(AppRoutes.libraryMediaPath(item.id));
    return;
  }
  context.push(AppRoutes.homeFeaturePath(item.id));
}
