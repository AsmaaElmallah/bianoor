import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_art.dart';
import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/ai_providers.dart';
import '../ai_assistant_screen.dart';

/// Opens «مساعدة بيانور» as a floating window over the current screen.
Future<void> showAiChatPopup(BuildContext context, {String? initialQuestion}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'قفل المساعدة',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => _ChatPopup(initialQuestion: initialQuestion),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
          alignment: AlignmentDirectional.bottomEnd.resolve(Directionality.of(ctx)),
          child: child,
        ),
      );
    },
  );
}

class _ChatPopup extends StatelessWidget {
  const _ChatPopup({this.initialQuestion});

  final String? initialQuestion;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + keyboard),
        child: Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onPrimaryFixed.withValues(alpha: 0.45),
                    blurRadius: 60,
                    spreadRadius: -18,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox.expand(
                  child: AiAssistantScreen(initialQuestion: initialQuestion, popup: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The only AI entry on the home screen: a floating, gently bobbing button.
class AiLauncherButton extends ConsumerStatefulWidget {
  const AiLauncherButton({super.key});

  @override
  ConsumerState<AiLauncherButton> createState() => _AiLauncherButtonState();
}

class _AiLauncherButtonState extends ConsumerState<AiLauncherButton> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseBootstrap.isEnabled) return const SizedBox.shrink();
    final settings = ref.watch(aiSettingsProvider).valueOrNull;
    if (settings != null && !settings.enabled) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: 'افتحي مساعدة بيانور',
      child: Tooltip(
        message: 'اسألي بيانور',
        child: GestureDetector(
          onTap: () => showAiChatPopup(context),
          child: AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)),
              child: child,
            ),
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  transform: GradientRotation(200 * math.pi / 180),
                  colors: [
                    AppColors.primaryFixedDim,
                    Color(0xFFF7C550),
                    Color(0xFFFF8A5C),
                    AppColors.primaryFixedDim,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onPrimaryFixed.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [AppColors.primary, AppColors.onPrimaryFixedVariant],
                  ),
                ),
                alignment: Alignment.center,
                child: Image.asset(AppArt.sparkles, width: 32, height: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
