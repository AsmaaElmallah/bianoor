/// Legal / store URLs from dart-defines (production).
class AppLegal {
  AppLegal._();

  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://bayanour.app/privacy',
  );

  static const termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://bayanour.app/terms',
  );
}
