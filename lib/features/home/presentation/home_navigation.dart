import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/home_menu_item.dart';

void openHomeMenuItem(BuildContext context, HomeMenuItem item) {
  if (item.id == 'lesson_quran') {
    context.push(AppRoutes.quranLesson);
    return;
  }
  context.push(AppRoutes.homeFeaturePath(item.id));
}
