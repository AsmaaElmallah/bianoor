import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../application/ai_providers.dart';
import '../ai_assistant_screen.dart';
import 'ai_orb.dart';

/// Opens the assistant over the whole screen.
Future<void> showAiChatPopup(BuildContext context, {String? initialQuestion}) {
  return _openLandingChat(context, initialQuestion: initialQuestion);
}

Future<void> _openLandingChat(BuildContext context, {String? initialQuestion}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'قفل المساعدة',
    barrierColor: AiSiteColors.cream50,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (dialogContext, _, __) {
      return _FullScreenChat(initialQuestion: initialQuestion);
    },
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: AiSiteColors.ease, reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

/// Opens «مساعدة بيانور» across the whole screen.
class AiLauncherButton extends ConsumerStatefulWidget {
  const AiLauncherButton({super.key});

  @override
  ConsumerState<AiLauncherButton> createState() => _AiLauncherButtonState();
}

class _AiLauncherButtonState extends ConsumerState<AiLauncherButton> {
  bool _open = false;

  Future<void> _openChat() async {
    setState(() => _open = true);
    await _openLandingChat(context);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseBootstrap.isEnabled) return const SizedBox.shrink();
    final settings = ref.watch(aiSettingsProvider).valueOrNull;
    if (settings != null && !settings.enabled) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: _open,
      child: Opacity(
        opacity: _open ? 0 : 1,
        child: AiLauncherPill(onTap: _openChat),
      ),
    );
  }
}

class _FullScreenChat extends StatelessWidget {
  const _FullScreenChat({this.initialQuestion});

  final String? initialQuestion;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // viewPadding keeps the composer above the system nav even inside a dialog.
    return Material(
      color: AiSiteColors.cream50,
      child: Padding(
        padding: EdgeInsets.only(
          top: media.viewPadding.top,
          bottom: media.viewPadding.bottom + media.viewInsets.bottom,
        ),
        child: AiAssistantScreen(popup: true, initialQuestion: initialQuestion),
      ),
    );
  }
}
