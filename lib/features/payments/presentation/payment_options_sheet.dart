import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../data/payment_settings_repository.dart';
import '../data/paypal_checkout_service.dart';
import '../domain/payment_item.dart';

/// PayPal (or card through PayPal) is the only payment method.
/// Returns true once the payment is captured and access granted.
Future<bool> payWithPaypal(BuildContext context, WidgetRef ref, PaymentItem item) async {
  final messenger = ScaffoldMessenger.of(context);
  final settings = await ref.read(paymentSettingsProvider.future);
  if (!context.mounted) return false;
  if (!settings.paypalEnabled) {
    messenger.showSnackBar(const SnackBar(content: Text('الدفع متوقف مؤقتاً، حاولي بعد شوية.')));
    return false;
  }
  if (item.usdLabel == null) {
    messenger.showSnackBar(const SnackBar(content: Text('السعر هيتحدد قريب.')));
    return false;
  }
  return showPaypalCheckout(context, item);
}

/// Opens PayPal checkout and returns true once payment is confirmed.
Future<bool> showPaypalCheckout(BuildContext context, PaymentItem item) async {
  final paid = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PaypalCheckoutDialog(item: item),
  );
  return paid == true;
}

enum _PaypalStep { starting, waiting, checking, failed }

class _PaypalCheckoutDialog extends ConsumerStatefulWidget {
  const _PaypalCheckoutDialog({required this.item});

  final PaymentItem item;

  @override
  ConsumerState<_PaypalCheckoutDialog> createState() => _PaypalCheckoutDialogState();
}

class _PaypalCheckoutDialogState extends ConsumerState<_PaypalCheckoutDialog> with WidgetsBindingObserver {
  _PaypalStep _step = _PaypalStep.starting;
  PaypalOrder? _order;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _step == _PaypalStep.waiting) _check(auto: true);
  }

  Future<void> _start() async {
    try {
      final order = await ref.read(paypalCheckoutServiceProvider).createOrder(widget.item);
      if (!mounted) return;
      setState(() {
        _order = order;
        _step = _PaypalStep.waiting;
      });
      await _openCheckout();
    } on PaypalException catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _PaypalStep.failed;
        _message = e.message;
      });
    }
  }

  Future<void> _openCheckout() async {
    final url = _order?.approveUrl;
    if (url == null) return;
    final ok = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (!ok) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _check({bool auto = false}) async {
    final order = _order;
    if (order == null) return;
    setState(() {
      _step = _PaypalStep.checking;
      _message = null;
    });
    final paid = await ref.read(paypalCheckoutServiceProvider).confirm(order.id);
    if (!mounted) return;
    if (paid) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _step = _PaypalStep.waiting;
      _message = auto ? null : 'الدفع لسه ما اكتملش. كمّلي الدفع في صفحة PayPal وبعدين تحققي تاني.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _step == _PaypalStep.starting || _step == _PaypalStep.checking;
    final price = widget.item.usdLabel;
    return AlertDialog(
      title: const Text('الدفع بـ PayPal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            price == null ? widget.item.title : '${widget.item.title} — $price',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (busy) ...[
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 14),
            Text(_step == _PaypalStep.starting ? 'جاري فتح صفحة الدفع…' : 'جاري التحقق من الدفع…'),
          ] else if (_step == _PaypalStep.failed)
            Text(_message ?? 'حصلت مشكلة، حاولي تاني.')
          else ...[
            const Text('كمّلي الدفع في الصفحة اللي اتفتحت، وبعد ما تخلّصي ارجعي هنا وهنتأكد تلقائي.'),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        if (_step == _PaypalStep.waiting) ...[
          TextButton(onPressed: _openCheckout, child: const Text('افتحي صفحة الدفع')),
          FilledButton(onPressed: () => _check(), child: const Text('تحققي من الدفع')),
        ],
      ],
    );
  }
}
