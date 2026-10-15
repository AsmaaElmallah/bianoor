import 'package:bayanour/features/ai/application/ai_voice.dart';
import 'package:bayanour/features/ai/presentation/widgets/ai_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('speech text drops markdown, emojis and links', () {
    final chunks = speechChunks('### النوم\n- **نامي** بدري 😴\n1. رضعة قبل النوم. شوفي https://who.int');
    expect(chunks, ['النوم', 'نامي بدري', '1، رضعة قبل النوم.', 'شوفي']);
  });

  testWidgets('markdown renders headings, bullets, numbers and bold while half-written', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AiMarkdown(text: '### عنوان\n- نقطة **مهمة**\n2. خطوة\nكلام **نص مكتوب')),
    ));
    expect(find.textContaining('عنوان'), findsOneWidget);
    expect(find.textContaining('نقطة مهمة'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
  });
}
