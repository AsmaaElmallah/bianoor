import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payment_settings_repository.dart';
import '../data/paypal_checkout_service.dart';
import '../domain/payment_item.dart';

enum PaymentChoice {
  /// Caller should run its store (Google Play) purchase flow.
  store,

  /// Paid online (PayPal) and access is already granted.
  paidOnline,
}

/// [storeLabel] non-null shows the store option with that label.
Future<PaymentChoice?> showPaymentOptions(
  BuildContext context, {
  required PaymentItem item,
  String? storeLabel,
}) {
  return showModalBottomSheet<PaymentChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PaymentOptionsSheet(item: item, storeLabel: storeLabel),
  );
}

class _PaymentOptionsSheet extends ConsumerStatefulWidget {
  const _PaymentOptionsSheet({required this.item, this.storeLabel});

  final PaymentItem item;
  final String? storeLabel;

  @override
  ConsumerState<_PaymentOptionsSheet> createState() => _PaymentOptionsSheetState();
}

class _PaymentOptionsSheetState extends ConsumerState<_PaymentOptionsSheet> {
  bool _manualOpen = false;

  Future<void> _payWithPaypal() async {
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaypalCheckoutDialog(item: widget.item),
    );
    if (paid == true && mounted) Navigator.of(context).pop(PaymentChoice.paidOnline);
  }

  Future<void> _sendReceipt(PaymentSettings settings) async {
    final item = widget.item;
    final email = SupabaseBootstrap.isReady ? SupabaseBootstrap.client.auth.currentUser?.email : null;
    final price = item.priceLabel.isNotEmpty ? item.priceLabel : (item.usdLabel ?? '');
    final what = item.kind == PaymentKind.subscription ? 'الاشتراك في ${item.title}' : 'دورة: ${item.title}';
    final message = [
      'مرحباً، حوّلت مبلغ $what${price.isNotEmpty ? ' ($price)' : ''}، وهبعت صورة الإيصال.',
      if (email != null && email.isNotEmpty) 'إيميلي في التطبيق: $email',
    ].join('\n');
    final uri = Uri.https('wa.me', '/${settings.whatsappNumber}', {'text': message});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح واتساب، تأكدي أنه مثبت على جهازك.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final asyncSettings = ref.watch(paymentSettingsProvider);
    final settings = asyncSettings.valueOrNull ?? const PaymentSettings();
    final usd = item.usdLabel;
    final showPaypal = settings.paypalEnabled && usd != null;
    final showManual = settings.canPayManually;
    final showStore = widget.storeLabel != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'اختاري طريقة الدفع',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (asyncSettings.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                if (showStore)
                  _OptionTile(
                    icon: Symbols.shop,
                    title: 'الدفع عن طريق المتجر',
                    subtitle: widget.storeLabel!,
                    onTap: () => Navigator.of(context).pop(PaymentChoice.store),
                  ),
                if (showPaypal)
                  _OptionTile(
                    icon: Symbols.credit_card,
                    title: 'PayPal أو بطاقة بنكية',
                    subtitle: 'الاشتراك يتفعّل تلقائي بعد الدفع — $usd',
                    onTap: _payWithPaypal,
                  ),
                if (showManual)
                  _OptionTile(
                    icon: Symbols.account_balance,
                    title: 'تحويل يدوي',
                    subtitle: 'حوّلي المبلغ وابعتي الإيصال على واتساب',
                    trailing: Icon(_manualOpen ? Symbols.expand_less : Symbols.expand_more),
                    onTap: () => setState(() => _manualOpen = !_manualOpen),
                    expanded: _manualOpen
                        ? _ManualDetails(
                            settings: settings,
                            priceLabel: item.priceLabel.isNotEmpty ? item.priceLabel : (usd ?? ''),
                            onSend: () => _sendReceipt(settings),
                          )
                        : null,
                  ),
                if (!showStore && !showPaypal && !showManual)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('طرق الدفع غير متاحة حالياً، حاولي لاحقاً.', textAlign: TextAlign.center),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.expanded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    trailing ?? const Icon(Symbols.chevron_left, color: AppColors.outline),
                  ],
                ),
                if (expanded != null) ...[const SizedBox(height: 12), expanded!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualDetails extends StatelessWidget {
  const _ManualDetails({required this.settings, required this.priceLabel, required this.onSend});

  final PaymentSettings settings;
  final String priceLabel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instructions = settings.manualInstructions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (priceLabel.isNotEmpty)
          Text('المبلغ: $priceLabel', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (instructions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(instructions, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: instructions));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ')));
              },
              icon: const Icon(Symbols.content_copy, size: 18),
              label: const Text('نسخ البيانات'),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'بعد التحويل ابعتي صورة الإيصال، وهنفعّل لك في أقرب وقت.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onSend,
          icon: const Icon(Symbols.chat),
          label: const Text('ابعتي الإيصال على واتساب'),
        ),
      ],
    );
  }
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
    return AlertDialog(
      title: const Text('الدفع بـ PayPal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
