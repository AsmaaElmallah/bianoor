import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/mothers_club_provider.dart';

class MothersClubCreatePostScreen extends ConsumerStatefulWidget {
  const MothersClubCreatePostScreen({super.key});

  @override
  ConsumerState<MothersClubCreatePostScreen> createState() =>
      _MothersClubCreatePostScreenState();
}

class _MothersClubCreatePostScreenState
    extends ConsumerState<MothersClubCreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  String? _categoryId;
  bool _sending = false;
  final _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _imageBytes = bytes;
    });
  }

  void _removeImage() => setState(() {
        _pickedImage = null;
        _imageBytes = null;
      });

  String? _imageExtension() {
    final name = _pickedImage?.name;
    if (name == null || !name.contains('.')) return 'jpg';
    return name.split('.').last.toLowerCase();
  }

  String? _imageContentType() {
    switch (_imageExtension()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (user == null) {
      if (!mounted) return;
      context.push(AppRoutes.login);
      return;
    }

    setState(() => _sending = true);
    try {
      final imageBytes = _imageBytes;

      await ref.read(mothersClubRepositoryProvider).createPost(
            userId: user.id,
            authorDisplayName: user.name ?? user.email.split('@').first,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            tag: _tagController.text.trim().isEmpty
                ? null
                : _tagController.text.trim(),
            categoryId: _categoryId,
            imageBytes: imageBytes,
            imageExtension: _imageExtension(),
            imageContentType: _imageContentType(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم إرسال منشوركِ للمراجعة — سيظهر بعد الموافقة.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      );
      context.pop();
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('انتهت مهلة الاتصال — حاولي مرة أخرى')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final hint = msg.contains('mothers_club') || msg.contains('does not exist')
            ? '\nهل نفّذتِ migrations نادي الأمهات (06–08) على Supabase؟'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر النشر: $msg$hint')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(mothersClubCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'منشور جديد',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  TactileClayCard(
                    child: Text(
                      'شاركي تجربتك مع الأمهات. المنشور يُراجع قبل النشر.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      hintText: 'موضوع المناقشة',
                      hintStyle: AppTextField.hintStyle(theme),
                      border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 4) ? 'أدخلي عنواناً' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    textAlign: TextAlign.right,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'التفاصيل',
                      hintText: 'اكتبي سؤالك أو تجربتك…',
                      hintStyle: AppTextField.hintStyle(theme),
                      border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? 'أدخلي تفاصيل أكثر' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tagController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'الوسم (اختياري)',
                      hintText: '#تغذية_الطفل',
                      hintStyle: AppTextField.hintStyle(theme),
                      border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'صورة (اختياري)',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_imageBytes != null) ...[
                    Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.brMd,
                          child: Image.memory(
                            _imageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.close, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _pickImage,
                    icon: Icon(Symbols.add_photo_alternate, color: AppColors.primary),
                    label: Text(
                      _pickedImage == null ? 'إرفاق صورة' : 'تغيير الصورة',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (result) {
                      final cats = result.data;
                      if (cats.isEmpty) return const SizedBox.shrink();
                      return DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: InputDecoration(
                          labelText: 'التصنيف',
                          border: OutlineInputBorder(borderRadius: AppRadius.brMd),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('عام'),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TactileClayButton(
                    label: _sending ? 'جاري الإرسال…' : 'إرسال للمراجعة',
                    onPressed: _sending ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
