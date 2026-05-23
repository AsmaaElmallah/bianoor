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

  static TextStyle hintStyle(ThemeData theme) =>
      theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.hintPlaceholder,
            fontWeight: FontWeight.w500,
          ) ??
      const TextStyle(
        color: AppColors.hintPlaceholder,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = hintStyle(theme);
    const iconColor = AppColors.hintPlaceholder;

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
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primary,
          decoration: beboPillBorder
              ? InputDecoration(
                  hintText: this.hint,
                  hintStyle: hint,
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
                            color: iconColor,
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
                            color: iconColor,
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
                  hintText: this.hint,
                  hintStyle: hint,
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
                            color: iconColor,
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
                            color: iconColor,
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
                    borderSide: BorderSide(color: AppColors.outline, width: 1),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.brLg,
                    borderSide: BorderSide(color: AppColors.outline, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brLg,
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.brLg,
                    borderSide: BorderSide(color: AppColors.error, width: 1.5),
                  ),
                ),
        ),
      ],
    );
  }
}
