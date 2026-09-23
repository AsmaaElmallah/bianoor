import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bayanour/core/constants/app_legal.dart';
import 'package:bayanour/core/storage/locale_provider.dart';
import 'package:bayanour/features/subscription/data/subscription_cloud_repository.dart';

void main() {
  group('AppLegal', () {
    test('defaults to bayanour.app URLs', () {
      expect(AppLegal.privacyPolicyUrl, contains('privacy'));
      expect(AppLegal.termsUrl, contains('terms'));
    });
  });

  group('locale helpers', () {
    test('Arabic and Urdu are RTL', () {
      expect(isRtlLocale(const Locale('ar')), isTrue);
      expect(isRtlLocale(const Locale('ur')), isTrue);
      expect(isRtlLocale(const Locale('en')), isFalse);
    });
  });

  group('UserSubscription', () {
    test('active when status active and not expired', () {
      final sub = UserSubscription(
        id: '1',
        planId: 'monthly',
        status: 'active',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      );
      expect(sub.isActive, isTrue);
    });

    test('inactive when expired', () {
      final sub = UserSubscription(
        id: '1',
        planId: 'monthly',
        status: 'active',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );
      expect(sub.isActive, isFalse);
    });
  });
}
