import 'dart:io';
import 'dart:ui' as ui;

import 'package:bayanour/core/constants/app_assets.dart';
import 'package:bayanour/core/router/app_routes.dart';
import 'package:bayanour/core/theme/app_colors.dart';
import 'package:bayanour/features/activities/domain/activities_catalog.dart';
import 'package:bayanour/features/support/domain/support_topics_data.dart';
import 'package:bayanour/shared/widgets/icon_3d.dart';
import 'package:bayanour/shared/widgets/mascot_message.dart';
import 'package:bayanour/shared/widgets/media_age/media_age_groups_screen.dart';
import 'package:bayanour/shared/widgets/media_age/media_age_hub_config.dart';
import 'package:bayanour/core/theme/app_theme.dart';
import 'package:bayanour/features/home/domain/home_menu_data.dart';
import 'package:bayanour/features/home/presentation/widgets/home_section_block.dart';
import 'package:bayanour/features/subscription/application/premium_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont() async {
  final loader = FontLoader('XPNiloofar');
  for (final f in ['XB Niloofar.ttf', 'XB NiloofarBd.ttf']) {
    final bytes = await File('../Niloofar/$f').readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _shoot(WidgetTester tester, Key key, String name) async {
  await tester.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      final img = el.widget as Image;
      await precacheImage(img.image, el).timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    }
  });
  await tester.pump(const Duration(milliseconds: 100));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('../../qa_shots/design/$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

Widget _app(Key key, Widget child) => ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(key: key, child: child),
        ),
      ),
    );

void main() {
  testWidgets('age groups preview', (tester) async {
    await tester.runAsync(_loadFont);
    tester.view.physicalSize = const Size(720, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const key = Key('ages');
    await tester.pumpWidget(_app(
      key,
      MediaAgeGroupsScreen(
        config: MediaAgeHubConfig.activities,
        heroTitle: 'أنشطة حسب عمر الطفل',
        heroSubtitle: 'لعب إبداعي ومشاركة — اختاري عمر طفلكِ.',
        hubPathBuilder: AppRoutes.activitiesHubPath,
        groups: [
          for (final g in activityAgeGroups)
            MediaAgeGroupCardData(
              id: g.id,
              title: g.title,
              subtitle: g.subtitle,
              icon: g.icon,
              itemCount: g.items.length,
              hasContent: g.items.isNotEmpty,
            ),
        ],
      ),
    ));
    await _shoot(tester, key, 'ages_preview');
  });

  testWidgets('states preview', (tester) async {
    await tester.runAsync(_loadFont);
    tester.view.physicalSize = const Size(720, 2900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const key = Key('states');
    await tester.pumpWidget(_app(
      key,
      Material(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in problemSolvingTopics.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Icon3D(art: null, icon: t.icon, size: 34),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t.title)),
                  ]),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D4DC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    for (final a in [
                      AppAssets.heroQuran,
                      AppAssets.heroMath,
                      AppAssets.heroVisual,
                      AppAssets.heroEmotional,
                    ])
                      Image.asset(a, width: 150, height: 150),
                  ],
                ),
              ),
              const SizedBox(
                height: 330,
                child: MascotMessage(
                  title: 'مفيش إشعارات لسه',
                  message: 'أول ما ينزل جديد هيوصلك هنا.',
                ),
              ),
              SizedBox(
                height: 330,
                child: MascotMessage.error(onAction: () {}),
              ),
            ],
          ),
        ),
      ),
    ));
    await _shoot(tester, key, 'states_preview');
  });

  testWidgets('home design preview', (tester) async {
    await tester.runAsync(_loadFont);
    tester.view.physicalSize = const Size(720, 2900);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    const key = Key('preview');
    final ids = ['start_learning', 'lessons', 'support', 'library'];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [unlockedLessonDaysProvider.overrideWith((ref) async => 1)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(
              key: key,
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final id in ids) ...[
                      HomeSectionBlock(section: homeSectionById(id)!),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // ignore: avoid_print
    print('pumped');
    await tester.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        final img = el.widget as Image;
        await precacheImage(img.image, el).timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      }
    });
    // ignore: avoid_print
    print('images ready');
    await tester.pump(const Duration(milliseconds: 100));

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('../../qa_shots/design/home_preview.png').writeAsBytes(png!.buffer.asUint8List());
    });
  });
}
