import 'package:flutter/material.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.bgColor,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final Color bgColor;
}
