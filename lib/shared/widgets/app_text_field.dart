import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSuffixTap,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.textInputAction,
    this.beboPillBorder = false,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  /// BeBo-style: white fill, thin grey outline, large pill radius.
  final bool beboPillBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: beboPillBorder
                  ? AppColors.beboIndigoHeading
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          validator: validator,
          textInputAction: textInputAction,
          style: theme.textTheme.bodyLarge,
          decoration: beboPillBorder
              ? InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: AppColors.surfaceBright,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  prefixIcon: icon != null
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 14,
                            end: 8,
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  suffixIcon: suffixIcon != null
                      ? IconButton(
                          onPressed: onSuffixTap,
                          icon: Icon(
                            suffixIcon,
                            color: AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: AppColors.beboMarketingPurple.withValues(
                        alpha: 0.55,
                      ),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                )
              : InputDecoration(
                  hintText: hint,
                  // In RTL screens, prefix icon appears on the right side.
                  prefixIcon: icon != null
                      ? Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 14,
                            end: 8,
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.outlineVariant,
                            size: 22,
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  suffixIcon: suffixIcon != null
                      ? IconButton(
                          onPressed: onSuffixTap,
                          icon: Icon(
                            suffixIcon,
                            color: AppColors.outlineVariant,
                            size: 22,
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.brLg,
                    borderSide: BorderSide.none,
                  ),
                ),
        ),
      ],
    );
  }
}
