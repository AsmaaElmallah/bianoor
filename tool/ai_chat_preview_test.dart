import 'dart:io';
import 'dart:ui' as ui;

import 'package:bayanour/core/storage/prefs_service.dart';
import 'package:bayanour/core/theme/app_colors.dart';
import 'package:bayanour/core/theme/app_theme.dart';
import 'package:bayanour/features/ai/application/ai_providers.dart';
import 'package:bayanour/features/ai/data/ai_models.dart';
import 'package:bayanour/features/ai/presentation/ai_assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont() async {
  final loader = FontLoader('XPNiloofar');
  for (final f in ['XB Niloofar.ttf', 'XB NiloofarBd.ttf']) {
    final bytes = await File('../Niloofar/$f').readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

class _FakeChat extends AiChatNotifier {
  _FakeChat(this._state);

  final AiChatState _state;

  @override
  Future<AiChatState> build() async => _state;
}

AiMessage _msg(String id, {required bool user, required String text, Map<String, dynamic> payload = const {}}) =>
    AiMessage(id: id, isUser: user, isEmergency: false, content: text, payload: payload, createdAt: DateTime(2026));

Future<void> _shot(WidgetTester tester, AiChatState chat, String name) async {
  await tester.runAsync(_loadFont);
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  const key = Key('preview');

  await tester.pumpWidget(ProviderScope(
    overrides: [
      prefsServiceProvider.overrideWithValue(PrefsService(prefs)),
      aiChatProvider.overrideWith(() => _FakeChat(chat)),
      aiDailyPlanProvider.overrideWith((ref) async => const AiPlanResult(
            status: AiStatus.ok,
            plan: AiDailyPlan(
              tip: '',
              activities: [AiPlanActivity(title: 'لعبة الكوباية والمكعب', minutes: 5, why: '', steps: [])],
              quranMoment: '',
              sources: [],
            ),
          )),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Stack(
            children: [
              Container(color: AppColors.background),
              Container(color: Colors.black.withValues(alpha: 0.28)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 40, 12, 16),
                child: Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: const SizedBox.expand(child: AiAssistantScreen(popup: true)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      await precacheImage((el.widget as Image).image, el).timeout(const Duration(seconds: 5), onTimeout: () {});
    }
  });
  await tester.pump(const Duration(milliseconds: 100));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('../../qa_shots/design/$name.png').writeAsBytes(png!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('ai chat welcome', (tester) async {
    await _shot(tester, const AiChatState(), 'ai_chat_welcome');
  });

  testWidgets('ai chat conversation', (tester) async {
    await _shot(
      tester,
      AiChatState(messages: [
        _msg('u1', user: true, text: 'طفلي 9 شهور ومش بينام قبل 12 بالليل'),
        _msg(
          'a1',
          user: false,
          text: '## نوم أهدى بالليل\n'
              'ده شائع في السن ده، وغالباً بيتظبط بروتين ثابت.\n\n'
              '- **ثبّتي ميعاد** الحمام والرضعة الأخيرة كل يوم.\n'
              '- **قللي النور** والشاشات قبل النوم بساعة.\n'
              '- خلي آخر قيلولة تخلص قبل 4 العصر.',
          payload: const {
            'format': 'md',
            'followups': ['إزاي أعمل روتين نوم؟', 'إمتى أقلق؟'],
          },
        ),
      ]),
      'ai_chat_conversation',
    );
  });
}
