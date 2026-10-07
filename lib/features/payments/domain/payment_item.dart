enum PaymentKind { subscription, course }

/// Something the mother can pay for: a subscription plan or a paid course.
class PaymentItem {
  const PaymentItem({
    required this.kind,
    required this.id,
    required this.title,
    this.priceLabel = '',
    this.priceUsd,
  });

  final PaymentKind kind;
  final String id;
  final String title;
  final String priceLabel;
  final double? priceUsd;

  String? get usdLabel => formatUsd(priceUsd);
}

String? formatUsd(double? p) {
  if (p == null || p <= 0) return null;
  return p == p.roundToDouble() ? '\$${p.toInt()}' : '\$${p.toStringAsFixed(2)}';
}

double? parseUsd(Object? value) {
  if (value is num) return value > 0 ? value.toDouble() : null;
  if (value is String) {
    final v = double.tryParse(value);
    return v != null && v > 0 ? v : null;
  }
  return null;
}
